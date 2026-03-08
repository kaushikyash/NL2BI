import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatButtonModule } from '@angular/material/button';
import { MatSelectModule } from '@angular/material/select';

@Component({
  selector: 'app-auth',
  imports: [FormsModule, MatCardModule, MatFormFieldModule, MatInputModule, MatButtonModule],
  templateUrl: './auth.html',
  styleUrl: './auth.css',
})
export class Auth {
  username: string = '';
  password: string = '';

  constructor(private router: Router) {}

  onLogin() {
    // Simple validation - in real app, authenticate with backend
    if (this.username && this.password) {
      // Store auth info (in real app, use service/token)
      localStorage.setItem('isLoggedIn', 'true');
      this.router.navigate(['/chat']);
    }
  }
}
