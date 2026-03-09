import { Routes } from '@angular/router';
import { Auth } from './auth/auth';
import { Chat } from './chat/chat';
import { Dashboard } from './dashboard/dashboard';
import { authGuard } from './guards/auth-guard';

export const routes: Routes = [
  { path: '', redirectTo: '/auth', pathMatch: 'full' },
  { path: 'auth', component: Auth },
  { path: 'chat', component: Chat, canActivate: [authGuard] },
  { path: 'dashboard', component: Dashboard, canActivate: [authGuard] }
];
