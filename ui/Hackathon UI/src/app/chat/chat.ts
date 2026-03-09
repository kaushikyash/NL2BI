import { Component, signal, ViewChild, ElementRef, AfterViewInit, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatSelectModule } from '@angular/material/select';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Message } from '../message.model';

type BackendResponse = {
  type: 'text' | 'table';
  message?: string;
  columns?: string[];
  data?: Array<Record<string, unknown>>;
  sql?: string;
  rows?: number;
  visualization?: {
    panel_type: string;
    unit: string;
    title: string;
    reason: string;
  };
  dashboard?: {
    enabled: boolean;
    title: string;
    uid: string;
  };
};

@Component({
  selector: 'app-chat',
  imports: [CommonModule, FormsModule, MatCardModule, MatFormFieldModule, MatInputModule, MatButtonModule, MatSelectModule, MatSlideToggleModule],
  templateUrl: './chat.html',
  styleUrl: './chat.css',
})
export class Chat implements OnInit, AfterViewInit {
  messages = signal<Message[]>([]);
  newMessage: string = '';
  selectedDbType: string = 'ClickHouse';
  createDashboard: boolean = false;
  isLoading: boolean = false;

  @ViewChild('messageContainer') messageList!: ElementRef;

  constructor(private router: Router, private http: HttpClient) {
    this.selectedDbType = localStorage.getItem('dbType') || 'ClickHouse';
  }

  ngOnInit() {
    if (!localStorage.getItem('dbType')) {
      localStorage.setItem('dbType', this.selectedDbType);
    }
  }

  ngAfterViewInit() {}

  addMessage() {
    const message = this.newMessage.trim();
    if (!message || this.isLoading) {
      return;
    }

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

    const userMessage = this.createTextMessage('user', message);
    this.messages.update(msgs => [...msgs, userMessage]);
    this.scrollToBottom();

    this.newMessage = '';
    this.isLoading = true;

    console.log('[chat] submitting query', {
      question: message,
      create_dashboard: this.createDashboard,
      db_type: this.selectedDbType,
    });

    this.http.post<BackendResponse>('/query', {
      question: message,
      create_dashboard: this.createDashboard,
    }).subscribe({
      next: (response) => {
        console.log('[chat] backend response', response);
        const assistantMessages = this.mapBackendResponse(response);
        this.messages.update(msgs => [...msgs, ...assistantMessages]);
        this.isLoading = false;
        this.scrollToBottom();
      },
      error: (err) => {
        console.error('[chat] backend error', err);
        const errorText = err?.error?.detail || err?.message || 'Backend request failed.';
        this.messages.update(msgs => [
          ...msgs,
          this.createTextMessage('assistant', `Request failed: ${errorText}`),
        ]);
        this.isLoading = false;
        this.scrollToBottom();
      }
    });
  }

  logout() {
    localStorage.removeItem('isLoggedIn');
    localStorage.removeItem('dbType');
    this.router.navigate(['/auth']);
  }

  onDbTypeChange() {
    localStorage.setItem('dbType', this.selectedDbType);
  }

  private mapBackendResponse(response: BackendResponse): Message[] {
    const messages: Message[] = [];
    const sql = response.sql ? `\n\nSQL:\n${response.sql}` : '';
    const visualization = response.visualization
      ? `\n\nSuggested visualization: ${response.visualization.panel_type}`
      : '';

    if (response.type === 'text') {
      messages.push(
        this.createTextMessage(
          'assistant',
          `${response.message || 'No text response returned.'}${visualization}${sql}`
        )
      );
    } else {
      messages.push(
        this.createTableMessage(
          'assistant',
          `Returned ${response.rows ?? 0} rows.${visualization}${sql}`,
          response.columns || [],
          response.data || []
        )
      );
    }

    if (response.dashboard?.enabled) {
      messages.push(
        this.createTextMessage(
          'assistant',
          `Dashboard JSON generated: ${response.dashboard.title} (${response.dashboard.uid})`
        )
      );
    }

    return messages;
  }

  private createTextMessage(sender: string, text: string): Message {
    return {
      id: `${sender}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      type: 'text',
      sender,
      timestamp: new Date().toISOString(),
      content: { text }
    };
  }

  private createTableMessage(
    sender: string,
    text: string,
    headers: string[],
    rows: Array<Record<string, unknown>>
  ): Message {
    return {
      id: `${sender}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      type: 'table',
      sender,
      timestamp: new Date().toISOString(),
      content: {
        text,
        table: {
          headers,
          rows: rows.map(row => headers.map(header => this.formatCell(row[header])))
        }
      }
    };
  }

  private formatCell(value: unknown): string {
    if (value === null || value === undefined) {
      return '';
    }
    if (typeof value === 'object') {
      return JSON.stringify(value);
    }
    return String(value);
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
