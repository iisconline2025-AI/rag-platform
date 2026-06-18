import type { ChatMessageOut } from '../../../chat/types/chat';

interface MessageBubbleProps {
  message: ChatMessageOut;
}

export default function MessageBubble({ message }: MessageBubbleProps) {
  const isUser = message.role === 'user';

  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'}`}>
      <div
        className={[
          'max-w-[75%] whitespace-pre-wrap rounded-lg px-4 py-2 text-sm',
          isUser
            ? 'bg-indigo-600 text-white'
            : 'border border-slate-200 bg-white text-slate-800',
        ].join(' ')}
      >
        {message.content}
      </div>
    </div>
  );
}
