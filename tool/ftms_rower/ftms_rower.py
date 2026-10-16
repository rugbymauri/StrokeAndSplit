# /// script
# requires-python = ">=3.11"
# dependencies = ["bless>=0.3,<0.4"]
# ///
"""Software FTMS rower: plays an FTMS recording as a BlueZ GATT peripheral.

    uv run tool/ftms_rower/ftms_rower.py <recording.jsonl|.aergrow> [--loop]

The recording comes from `dart run erg_protocol:pm5_to_ftms`. The rower
advertises as "AergRow FTMS Rower" with the Fitness Machine service 0x1826
and the Rower bit in its service data, confirms Request Control and
Start/Resume on the control point and then sends the Rower Data records
(0x2AD1) at their recorded times. The protocol logic lives in Dart; this
script only replays bytes (Design D11).

Test it from another device (an Android phone): the adapter of this computer
cannot be peripheral and central for the app on the same machine.
"""

import argparse
import asyncio
import base64
import gzip
import json
import sys
from pathlib import Path

from bless import (
    BlessServer,
    GATTAttributePermissions,
    GATTCharacteristicProperties,
)
from bless.backends.bluezdbus.dbus import advertisement
from dbus_next import Variant

NAME = "AergRow FTMS Rower"
FTMS = "00001826-0000-1000-8000-00805f9b34fb"
FEATURE = "00002acc-0000-1000-8000-00805f9b34fb"
ROWER_DATA = "00002ad1-0000-1000-8000-00805f9b34fb"
CONTROL_POINT = "00002ad9-0000-1000-8000-00805f9b34fb"
MACHINE_STATUS = "00002ada-0000-1000-8000-00805f9b34fb"

# Service data of 0x1826: flags (machine available), machine type (bit 4: rower).
SERVICE_DATA = bytes([0x01, 0x10, 0x00])
# Fitness Machine Features: cadence, total distance, pace, expended energy,
# heart rate, elapsed time, power; no target settings.
FEATURES = (0x0002 | 0x0004 | 0x0020 | 0x0200 | 0x0400 | 0x1000 | 0x4000).to_bytes(4, "little") + bytes(4)

REQUEST_CONTROL, RESET, START, STOP = 0x00, 0x01, 0x07, 0x08
RESPONSE, SUCCESS, NOT_SUPPORTED = 0x80, 0x01, 0x02
STATUS_STARTED = 0x04

# Without a start command, start this long after a client connected.
START_WITHOUT_COMMAND = 2.0


def _with_service_data(init):
    def patched(self, *args, **kwargs):
        init(self, *args, **kwargs)
        self._service_data = {FTMS: Variant("ay", SERVICE_DATA)}

    return patched


advertisement.BlueZLEAdvertisement.__init__ = _with_service_data(advertisement.BlueZLEAdvertisement.__init__)


def load(path: Path) -> list[tuple[float, bytes]]:
    """The Rower Data records of a recording as (seconds, bytes)."""
    raw = path.read_bytes()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    lines = raw.decode().splitlines()
    header = json.loads(lines[0])
    if header.get("protocol") != "ftms":
        sys.exit(f"{path} is not an FTMS recording; convert it with `dart run erg_protocol:pm5_to_ftms`")
    records = []
    for line in lines[1:]:
        if not line.strip():
            continue
        packet = json.loads(line)
        if packet.get("c") == "2ad1":
            records.append((packet["t"] / 1000, base64.b64decode(packet["b"])))
    if not records:
        sys.exit(f"{path} has no Rower Data records")
    return records


class Rower:
    def __init__(self, records: list[tuple[float, bytes]], loop: bool):
        self.records = records
        self.loop = loop
        self.started = asyncio.Event()
        self.server: BlessServer | None = None

    def read(self, characteristic, **_):
        return characteristic.value

    def write(self, characteristic, value: bytearray, **_):
        if str(characteristic.uuid).lower() != CONTROL_POINT or not value:
            return
        op = value[0]
        result = SUCCESS if op in (REQUEST_CONTROL, START) else NOT_SUPPORTED
        print(f"control point: op 0x{op:02x} -> {'success' if result == SUCCESS else 'not supported'}")
        self.notify(CONTROL_POINT, bytes([RESPONSE, op, result]))
        if op == START:
            self.notify(MACHINE_STATUS, bytes([STATUS_STARTED]))
            self.started.set()

    def notify(self, uuid: str, value: bytes):
        self.server.get_characteristic(uuid).value = bytearray(value)
        self.server.update_value(FTMS, uuid)

    async def run(self):
        self.server = BlessServer(name=NAME)
        self.server.read_request_func = self.read
        self.server.write_request_func = self.write
        await self.server.add_new_service(FTMS)
        read, notify = GATTCharacteristicProperties.read, GATTCharacteristicProperties.notify
        readable, writeable = GATTAttributePermissions.readable, GATTAttributePermissions.writeable
        await self.server.add_new_characteristic(FTMS, FEATURE, read, bytearray(FEATURES), readable)
        await self.server.add_new_characteristic(FTMS, ROWER_DATA, notify, bytearray(self.records[0][1]), readable)
        await self.server.add_new_characteristic(
            FTMS,
            CONTROL_POINT,
            GATTCharacteristicProperties.write | GATTCharacteristicProperties.indicate,
            None,
            readable | writeable,
        )
        await self.server.add_new_characteristic(FTMS, MACHINE_STATUS, notify, None, readable)
        await self.server.start()
        print(f"advertising as {NAME!r}, {len(self.records)} records, waiting for a client …")
        try:
            await self.wait_for_start()
            while True:
                await self.play()
                if not self.loop:
                    break
            print("recording finished; Ctrl+C to stop")
            await asyncio.Event().wait()
        finally:
            await self.server.stop()

    async def wait_for_start(self):
        while not await self.server.is_connected():
            await asyncio.sleep(0.2)
        print("client connected")
        try:
            await asyncio.wait_for(self.started.wait(), START_WITHOUT_COMMAND)
        except TimeoutError:
            print("no start command, starting anyway")

    async def play(self):
        start = asyncio.get_running_loop().time() - self.records[0][0]
        for at, data in self.records:
            delay = start + at - asyncio.get_running_loop().time()
            if delay > 0:
                await asyncio.sleep(delay)
            self.notify(ROWER_DATA, data)
        print("end of recording")


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("recording", type=Path, help="FTMS recording (.jsonl or .aergrow)")
    parser.add_argument("--loop", action="store_true", help="start the recording again at its end")
    args = parser.parse_args()
    sys.stdout.reconfigure(line_buffering=True)
    try:
        asyncio.run(Rower(load(args.recording), args.loop).run())
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
