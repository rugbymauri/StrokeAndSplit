import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sessions/session_providers.dart';
import 'session_template.dart';
import 'template_repository.dart';

final templateRepositoryProvider = Provider<TemplateRepository>(
  (ref) => TemplateRepository(ref.watch(databaseProvider)),
);

/// All templates by name.
final templatesProvider = StreamProvider<List<SessionTemplate>>(
  (ref) => ref.watch(templateRepositoryProvider).watchAll(),
);
