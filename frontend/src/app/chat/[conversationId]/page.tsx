import ChatLayout from '../../../components/chat/ChatLayout';

interface ConversationPageProps {
  params: { conversationId: string };
}

export default function ConversationPage({ params }: ConversationPageProps) {
  return <ChatLayout conversationId={params.conversationId} />;
}
