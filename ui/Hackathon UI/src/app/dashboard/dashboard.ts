import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';

@Component({
  selector: 'app-dashboard',
  imports: [MatCardModule, MatButtonModule],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.css',
})
export class Dashboard implements OnInit {
  dbType: string = '';

  constructor(private router: Router) {}

  ngOnInit() {
    this.dbType = localStorage.getItem('dbType') || 'ClickHouse';
  }

  logout() {
    localStorage.removeItem('isLoggedIn');
    localStorage.removeItem('dbType');
    this.router.navigate(['/auth']);
  }

  goToChat() {
    this.router.navigate(['/chat']);
  }
}
