/// Действие в чате через WebSocket
abstract class ChatAction {
  final String type;

  const ChatAction({required this.type});
}

/// Действие создания сообщения
class CreateMessageAction extends ChatAction {
  final String text;
  final bool fromSpecialist;

  const CreateMessageAction({required this.text, required this.fromSpecialist}) : super(type: 'CREATE');

  Map<String, dynamic> toJson() {
    return {'type': type, 'text': text, 'fromSpecialist': fromSpecialist};
  }

  factory CreateMessageAction.fromJson(Map<String, dynamic> json) {
    return CreateMessageAction(
      text: json['text'] as String,
      fromSpecialist: json['fromSpecialist'] as bool? ?? false,
    );
  }
}

/// Действие чтения сообщения
class ReadMessageAction extends ChatAction {
  final String messageId;

  const ReadMessageAction({required this.messageId}) : super(type: 'READ');

  Map<String, dynamic> toJson() {
    return {'type': type, 'messageId': messageId};
  }

  factory ReadMessageAction.fromJson(Map<String, dynamic> json) {
    return ReadMessageAction(messageId: json['messageId'] as String);
  }
}
