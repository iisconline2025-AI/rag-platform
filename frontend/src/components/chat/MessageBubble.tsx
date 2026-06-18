import ReactMarkdown from 'react-markdown';
import rehypeHighlight from 'rehype-highlight';
import type { Components } from 'react-markdown';
import type { ChatMessageOut } from '../../../chat/types/chat';
import ClarificationBanner from './ClarificationBanner';
import FaithfulnessBadge from './FaithfulnessBadge';
import CitationsPanel from './CitationsPanel';

interface MessageBubbleProps {
  message: ChatMessageOut;
}

const markdownComponents: Components = {
  a: ({ children, ...props }) => (
    <a {...props} target="_blank" rel="noreferrer" className="underline">
      {children}
    </a>
  ),
  code: ({ className, children, ...props }) => {
    if (className) {
      return (
        <code className={`font-mono text-xs ${className}`} {...props}>
          {children}
        </code>
      );
    }
    return (
      <code className="rounded bg-slate-100 px-1 py-0.5 font-mono text-xs text-slate-800" {...props}>
        {children}
      </code>
    );
  },
  pre: ({ children, ...props }) => (
    <pre {...props} className="my-1 overflow-x-auto rounded-md bg-slate-900 p-3 text-xs text-slate-100">
      {children}
    </pre>
  ),
};

export default function MessageBubble({ message }: MessageBubbleProps) {
  const isUser = message.role === 'user';

  return (
    <div className="flex flex-col gap-2">
      <div className={`flex ${isUser ? 'justify-end' : 'justify-start'}`}>
        <div
          className={[
            'max-w-[75%] break-words rounded-lg px-4 py-2 text-sm',
            isUser
              ? 'whitespace-pre-wrap bg-indigo-600 text-white'
              : 'border border-slate-200 bg-white text-slate-800',
          ].join(' ')}
        >
          {isUser ? (
            message.content
          ) : (
            <ReactMarkdown rehypePlugins={[rehypeHighlight]} components={markdownComponents}>
              {message.content}
            </ReactMarkdown>
          )}
        </div>
      </div>

      {!isUser && (
        <div className="flex max-w-[75%] flex-col gap-2 pl-1">
          <ClarificationBanner requiresClarification={message.requires_clarification} />
          <FaithfulnessBadge score={message.faithfulness} />
          <CitationsPanel sources={message.sources} />
        </div>
      )}
    </div>
  );
}
