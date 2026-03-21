import { Navigate } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';

interface ProtectedRouteProps {
  children: React.ReactNode;
}

export default function ProtectedRoute({ children }: ProtectedRouteProps) {
  const { isAuthenticated } = useAuth();

  if (!isAuthenticated) {
    // Chuyển hướng về /login, giữ URL hiện tại để sau login redirect về đúng trang
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
}
