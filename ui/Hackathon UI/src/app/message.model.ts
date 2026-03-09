// Message model for API responses

export interface BaseMessage {
  id: string;
  sender: string;
  timestamp: string;
}

export interface TextContent {
  text: string;
}

export interface LinkContent {
  text: string;
  links: Array<{
    url: string;
    urlLabel: string;
  }>;
}

export interface ImageContent {
  text: string;
  image: {
    url: string;
    alt: string;
    width: number;
    height: number;
  };
}

export interface TableContent {
  text: string;
  table: {
    headers: string[];
    rows: string[][];
  };
}

export interface TextMessage extends BaseMessage {
  type: 'text';
  content: TextContent;
}

export interface LinkMessage extends BaseMessage {
  type: 'link';
  content: LinkContent;
}

export interface ImageMessage extends BaseMessage {
  type: 'image';
  content: ImageContent;
}

export interface TableMessage extends BaseMessage {
  type: 'table';
  content: TableContent;
}

export type Message = TextMessage | LinkMessage | ImageMessage | TableMessage;

// Utility class to handle messages
export class MessageHandler {
  static isTextMessage(message: Message): message is TextMessage {
    return message.type === 'text';
  }

  static isLinkMessage(message: Message): message is LinkMessage {
    return message.type === 'link';
  }

  static isImageMessage(message: Message): message is ImageMessage {
    return message.type === 'image';
  }

  static isTableMessage(message: Message): message is TableMessage {
    return message.type === 'table';
  }

  // Method to parse JSON string to Message
  static parseMessage(json: string): Message | null {
    try {
      const data = JSON.parse(json);
      // Basic validation
      if (data.id && data.type && data.sender && data.timestamp && data.content) {
        return data as Message;
      }
      return null;
    } catch {
      return null;
    }
  }

  // Method to create a message from object
  static createMessage(data: any): Message | null {
    if (data.id && data.type && data.sender && data.timestamp && data.content) {
      return data as Message;
    }
    return null;
  }
}