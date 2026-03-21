import React, { createContext, useContext, useState, useCallback } from 'react';
import type { User } from '@/types';
import api from '@/services/api';

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
}

interface AuthContextValue extends AuthState {
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const TOKEN_KEY = 'gmp_token';
const USER_KEY = 'gmp_user';

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AuthState>(() => {
    // Khôi phục trạng thái từ localStorage khi reload trang
    const token = localStorage.getItem(TOKEN_KEY);
    const userRaw = localStorage.getItem(USER_KEY);
    let user: User | null = null;
    try {
      if (userRaw) user = JSON.parse(userRaw);
    } catch {
      user = null;
    }
    return {
      user,
      token,
      isAuthenticated: !!token && !!user,
      isLoading: false,
    };
  });

  const login = useCallback(async (username: string, password: string) => {
    setState(s => ({ ...s, isLoading: true }));
    try {
      const response: any = await api.post('/auth/login', { username, password, platform: 'Web' });
      // Backend trả về: { success, data: { token, user } }
      const { token, user } = response.data ?? response;

      localStorage.setItem(TOKEN_KEY, token);
      localStorage.setItem(USER_KEY, JSON.stringify(user));

      setState({
        user,
        token,
        isAuthenticated: true,
        isLoading: false,
      });
    } catch (err) {
      setState(s => ({ ...s, isLoading: false }));
      throw err;
    }
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    setState({ user: null, token: null, isAuthenticated: false, isLoading: false });
  }, []);

  return (
    <AuthContext.Provider value={{ ...state, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth phải được dùng bên trong <AuthProvider>');
  return ctx;
}
