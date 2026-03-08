import { Component, signal, ViewChild, ElementRef, AfterViewInit } from '@angular/core';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatListModule } from '@angular/material/list';
import { MatSelectModule } from '@angular/material/select';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-chat',
  imports: [CommonModule, FormsModule, MatCardModule, MatFormFieldModule, MatInputModule, MatButtonModule, MatListModule, MatSelectModule],
  templateUrl: './chat.html',
  styleUrl: './chat.css',
})
export class Chat implements AfterViewInit {
  messages = signal<string[]>([]);
  newMessage: string = '';
  selectedDbType: string = '';

  @ViewChild('messageContainer') messageList!: ElementRef;

  constructor(private router: Router) {
    this.selectedDbType = localStorage.getItem('dbType') || '';
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
      this.messages.update(msgs => [...msgs, 'You: ' + message]);
      this.scrollToBottom();
      // Simulate a response
      setTimeout(() => {
        this.messages.update(msgs => [...msgs, 'Bot: This is a response to your query.']);
        this.scrollToBottom();
      }, 100);
      this.newMessage = '';
    }
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
