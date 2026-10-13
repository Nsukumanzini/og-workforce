import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/crm_inbox_repository.dart';
final crmInboxRepositoryProvider=Provider<CrmInboxRepository>((ref)=>throw UnimplementedError());
final crmContactsProvider=FutureProvider<List<CrmContact>>((ref)=>ref.read(crmInboxRepositoryProvider).contacts());
final inboxConversationsProvider=FutureProvider<List<InboxConversation>>((ref)=>ref.read(crmInboxRepositoryProvider).conversations());
final whatsappIntegrationProvider=FutureProvider<Map<String,dynamic>?>((ref)=>ref.read(crmInboxRepositoryProvider).integration());
