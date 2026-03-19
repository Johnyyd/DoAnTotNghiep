import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { appUsersApi } from '@/services/api';
import { Search, Users, Filter, Plus, Edit2, Trash2 } from 'lucide-react';

export default function AppUsers() {
  const [search, setSearch] = useState('');

  const { data: users, isLoading } = useQuery({
    queryKey: ['app-users'],
    queryFn: () => appUsersApi.getAll(),
  });

  const usersData = Array.isArray(users) ? users : (users as any)?.data ?? [];

  const normalizedUsers = usersData.map((m: any) => ({
    userId: m.UserId || m.userId,
    username: m.Username || m.username,
    fullName: m.FullName || m.fullName,
    role: m.Role || m.role || 'Operator',
    isActive: m.IsActive !== undefined ? m.IsActive : m.isActive,
    createdAt: m.CreatedAt || m.createdAt,
  }));

  const filteredUsers = normalizedUsers.filter((u: any) => {
    if (!u) return false;
    const term = search.toLowerCase();
    const fname = typeof u.fullName === 'string' ? u.fullName.toLowerCase() : '';
    const uname = typeof u.username === 'string' ? u.username.toLowerCase() : '';
    return fname.includes(term) || uname.includes(term);
  });

  const getRoleInfo = (role: string) => {
    switch (role) {
      case 'Admin':
        return { label: 'Quản trị viên', classes: 'bg-red-100 text-red-700' };
      case 'QualityControl':
        return { label: 'Kiểm soát chất lượng (QC)', classes: 'bg-purple-100 text-purple-700' };
      case 'Manager':
        return { label: 'Quản lý', classes: 'bg-blue-100 text-blue-700' };
      case 'Operator':
        return { label: 'Nhân viên vận hành', classes: 'bg-neutral-100 text-neutral-700' };
      default:
        return { label: role, classes: 'bg-neutral-100 text-neutral-700' };
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Quản Lý Người Dùng</h1>
          <p className="text-sm text-neutral-500 mt-1">
            Quản lý danh sách nhân viên, tài khoản hệ thống và phân quyền.
          </p>
        </div>
        <button className="btn-primary w-full sm:w-auto">
          <Plus className="w-5 h-5 mr-2" />
          Thêm người dùng mới
        </button>
      </div>

      <div className="bg-surface border border-neutral-200 rounded-xl overflow-hidden shadow-sm">
        <div className="p-4 border-b border-neutral-200 bg-neutral-50/50 flex flex-col sm:flex-row gap-4 justify-between">
          <div className="relative w-full sm:w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input
              type="text"
              placeholder="Tìm kiếm tài khoản, tên nhân viên..."
              value={search}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-shadow"
            />
          </div>
          <div className="flex gap-2">
            <button className="btn-secondary">
              <Filter className="w-4 h-4 mr-2" />
              Lọc kết quả
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-neutral-50 border-b border-neutral-200">
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">ID</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Tài khoản</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Họ và Tên</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Phân quyền</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Trạng thái</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Ngày tạo</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {isLoading ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-neutral-500">
                    <div className="flex items-center justify-center space-x-2">
                      <div className="w-5 h-5 border-2 border-primary-500 border-t-transparent rounded-full animate-spin" />
                      <span>Đang tải danh sách tài khoản...</span>
                    </div>
                  </td>
                </tr>
              ) : filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-neutral-500">
                    <Users className="w-12 h-12 text-neutral-300 mx-auto mb-3" />
                    <p className="text-lg font-medium text-neutral-900">Không tìm thấy tài khoản</p>
                    <p className="text-sm">Chưa có người dùng nào hoặc từ khóa không khớp.</p>
                  </td>
                </tr>
              ) : (
                filteredUsers.map((user: any) => (
                  <tr key={user.userId} className="hover:bg-neutral-50 transition-colors">
                    <td className="py-3 px-4 text-sm text-neutral-900 font-medium">#{user.userId}</td>
                    <td className="py-3 px-4 text-sm font-medium text-neutral-900 flex items-center">
                      <div className="w-8 h-8 rounded-full bg-gradient-to-br from-primary-400 to-primary-600 flex items-center justify-center text-white mr-3 font-bold text-xs">
                        {user.username.charAt(0).toUpperCase()}
                      </div>
                      {user.username}
                    </td>
                    <td className="py-3 px-4 text-sm text-neutral-600">{user.fullName}</td>
                    <td className="py-3 px-4">
                      {(() => {
                        const info = getRoleInfo(user.role);
                        return (
                          <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${info.classes}`}>
                            {info.label}
                          </span>
                        );
                      })()}
                    </td>
                    <td className="py-3 px-4">
                      {user.isActive ? (
                        <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">
                          <span className="w-1.5 h-1.5 rounded-full bg-green-500 mr-1.5"></span>
                          Đang hoạt động
                        </span>
                      ) : (
                        <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-neutral-100 text-neutral-600">
                          <span className="w-1.5 h-1.5 rounded-full bg-neutral-400 mr-1.5"></span>
                          Đã khóa
                        </span>
                      )}
                    </td>
                    <td className="py-3 px-4 text-sm text-neutral-500">
                      {user.createdAt ? new Date(user.createdAt).toLocaleDateString('vi-VN') : '-'}
                    </td>
                    <td className="py-3 px-4 text-right">
                      <div className="flex items-center justify-end space-x-2">
                        <button className="p-1.5 text-neutral-400 hover:text-primary-600 hover:bg-primary-50 rounded-lg transition-colors">
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 text-neutral-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
