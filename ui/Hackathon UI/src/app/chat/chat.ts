import { Component, signal, ViewChild, ElementRef, AfterViewInit, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatSelectModule } from '@angular/material/select';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Message, MessageHandler } from '../message.model';

@Component({
  selector: 'app-chat',
  imports: [CommonModule, FormsModule, MatCardModule, MatFormFieldModule, MatInputModule, MatButtonModule, MatSelectModule],
  templateUrl: './chat.html',
  styleUrl: './chat.css',
})
export class Chat implements OnInit, AfterViewInit {
  messages = signal<Message[]>([]);
  sampleMessages: Message[] = [];
  newMessage: string = '';
  selectedDbType: string = '';

  @ViewChild('messageContainer') messageList!: ElementRef;

  constructor(private router: Router, private http: HttpClient) {
    this.selectedDbType = localStorage.getItem('dbType') || '';
  }

  ngOnInit() {
    // Load sample messages but don't display them
    this.http.get<Message[]>('/assets/sample-messages.json').subscribe({
      next: (data) => {
        this.sampleMessages = data;
      },
      error: (err) => {
        console.error('Failed to load sample messages', err);
      }
    });
  }

  ngAfterViewInit() {
  }

  addMessage() {
    if (this.newMessage.trim()) {
      const message = this.newMessage.trim();
      if (message.toLowerCase() === 'cls') {
        this.messages.set([]);
        this.newMessage = '';
        return;
      }
      if (message.toLowerCase() === 'dashboard') {
        this.router.navigate(['/dashboard']);
        this.newMessage = '';
        return;
      }
      // Create user message
      const userMessage: Message = {
        id: 'user_' + Date.now(),
        type: 'text',
        sender: 'user',
        timestamp: new Date().toISOString(),
        content: { text: message }
      };
      this.messages.update(msgs => [...msgs, userMessage]);
      this.scrollToBottom();
      // Determine response type based on user input
      const responseType = this.determineResponseType(message);
      const responseMessage = this.getResponseByType(responseType);
      if (responseMessage) {
        this.messages.update(msgs => [...msgs, responseMessage]);
        this.scrollToBottom();
      }
      this.newMessage = '';
    }
  }

  private determineResponseType(userMessage: string): string {
    const lowerMessage = userMessage.toLowerCase();
    if (lowerMessage.includes('text')) {
      return 'text';
    } else if (lowerMessage.includes('image')) {
      return 'image';
    } else if (lowerMessage.includes('link')) {
      return 'link';
    } else if (lowerMessage.includes('table')) {
      return 'table';
    } else {
      // Default to text if no specific type mentioned
      return 'text';
    }
  }

  private getResponseByType(type: string): Message | null {
    const matchingMessages = this.sampleMessages.filter(msg => msg.type === type);
    if (matchingMessages.length > 0) {
      return matchingMessages[Math.floor(Math.random() * matchingMessages.length)];
    }
    return null;
  }

  logout() {
    localStorage.removeItem('isLoggedIn');
    localStorage.removeItem('dbType');
    this.router.navigate(['/auth']);
  }

  onDbTypeChange() {
    localStorage.setItem('dbType', this.selectedDbType);
  }

  private scrollToBottom() {
    if (this.messageList) {
      setTimeout(() => {
        const element = this.messageList.nativeElement;
        element.scrollTop = element.scrollHeight - element.clientHeight;
      }, 100);
    }
  }
}
