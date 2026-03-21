import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import { toast } from 'sonner';
import { Eye, EyeOff, Lock, User, AlertCircle } from 'lucide-react';

export default function Login() {
  const { login, isLoading } = useAuth();
  const navigate = useNavigate();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!username.trim() || !password.trim()) {
      setError('Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu.');
      return;
    }

    try {
      await login(username.trim(), password);
      toast.success('Đăng nhập thành công! Chào mừng trở lại.');
      navigate('/dashboard', { replace: true });
    } catch (err: any) {
      const msg =
        err?.response?.data?.message ||
        err?.message ||
        'Tên đăng nhập hoặc mật khẩu không đúng.';
      setError(msg);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-900 via-primary-800 to-primary-700 flex items-center justify-center p-4">
      {/* Background pattern */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-96 h-96 bg-white/5 rounded-full blur-3xl" />
        <div className="absolute -bottom-40 -left-40 w-96 h-96 bg-white/5 rounded-full blur-3xl" />
      </div>

      <div className="relative w-full max-w-md">
        {/* Card */}
        <div className="bg-white rounded-2xl shadow-2xl p-8">
          {/* Logo */}
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-primary-500 to-primary-700 rounded-2xl mb-4 shadow-lg">
              <span className="text-white font-bold text-xl">GMP</span>
            </div>
            <h1 className="text-2xl font-bold text-neutral-900">GMP-WHO System</h1>
            <p className="text-sm text-neutral-500 mt-1">Hệ thống quản lý sản xuất dược phẩm</p>
          </div>

          {/* Error message */}
          {error && (
            <div className="flex items-start space-x-2 p-3 mb-6 bg-red-50 border border-red-200 rounded-lg">
              <AlertCircle className="w-4 h-4 text-red-500 mt-0.5 shrink-0" />
              <p className="text-sm text-red-700">{error}</p>
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Username */}
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">
                Tên đăng nhập
              </label>
              <div className="relative">
                <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
                <input
                  id="login-username"
                  type="text"
                  value={username}
                  onChange={e => setUsername(e.target.value)}
                  placeholder="admin"
                  autoComplete="username"
                  className="w-full pl-10 pr-4 py-2.5 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-shadow text-neutral-900 placeholder:text-neutral-400"
                />
              </div>
            </div>

            {/* Password */}
            <div>
              <label className="block text-sm font-medium text-neutral-700 mb-1.5">
                Mật khẩu
              </label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
                <input
                  id="login-password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  placeholder="••••••••"
                  autoComplete="current-password"
                  className="w-full pl-10 pr-12 py-2.5 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-shadow text-neutral-900 placeholder:text-neutral-400"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(v => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-neutral-400 hover:text-neutral-600 transition-colors"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {/* Submit */}
            <button
              id="login-submit"
              type="submit"
              disabled={isLoading}
              className="w-full btn-primary py-2.5 flex items-center justify-center space-x-2 disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <>
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  <span>Đang đăng nhập...</span>
                </>
              ) : (
                <span>Đăng nhập</span>
              )}
            </button>
          </form>

          {/* Footer hint */}
          <div className="mt-6 p-3 bg-neutral-50 border border-neutral-200 rounded-lg">
            <p className="text-xs text-neutral-500 text-center font-medium mb-1">Tài khoản mặc định</p>
            <div className="grid grid-cols-3 gap-1 text-xs text-neutral-600 text-center">
              <span className="font-mono bg-white rounded px-1 py-0.5 border">admin / Admin@123</span>
              <span className="font-mono bg-white rounded px-1 py-0.5 border">qc01 / Qc@123456</span>
              <span className="font-mono bg-white rounded px-1 py-0.5 border">op01 / Op@123456</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
