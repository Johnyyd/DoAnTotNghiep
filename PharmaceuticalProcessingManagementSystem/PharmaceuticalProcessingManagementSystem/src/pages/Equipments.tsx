import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { equipmentsApi } from '@/services/api';
import { Search, Settings, Filter, Plus, PenTool, CheckCircle2, AlertTriangle, AlertOctagon } from 'lucide-react';

export default function Equipments() {
  // Định nghĩa Local Data State (Hook) để cập nhật DOM mà không reload nguyên trang HTML
  const [search, setSearch] = useState(''); // Tracking từ khóa gõ vào chuỗi tìm kiếm mã thiết bị
  const [statusFilter, setStatusFilter] = useState(''); // Theo dõi tùy chỉnh bộ màng lọc theo danh mục Check box

  // Khai báo React Query để fetch dữ liệu gọi lên API máy chủ. Tự động xử lý Caching thông minh (giảm lượt Request).
  // - queryKey: Biến chìa khóa cache. Nếu `statusFilter` thay đổi, thư viện Query tự động bắn signal Refetch API ngầm định
  // - queryFn: Logic Action kết nối mạng (Network Tunneling) sử dụng Axios/Fetch ngầm từ equipmentsApi class
  const { data: equipments, isLoading } = useQuery({
    queryKey: ['equipments', statusFilter],
    queryFn: () => equipmentsApi.getAll({ status: statusFilter || undefined }),
  });

  // Lọc nhiễu Response API (Fallback an toàn): Cam kết trích array chuẩn tránh Type Error Mapping `.map is not a function`
  // Trong trường hợp API wrap thành `{ data: [] }` hoặc chỉ quăng mảng raw `[]`
  const equipData = Array.isArray(equipments) ? equipments : (equipments as any)?.data ?? [];

  // Data Normalization (Chuẩn hóa Object Key Casing). Hóa giải mâu thuẫn phong cách mã (C# dùng PascalCase còn JS dùng camelCase)
  const normalizedEquips = equipData.map((m: any) => ({
    equipmentId: m.EquipmentId || m.equipmentId,
    equipmentCode: m.EquipmentCode || m.equipmentCode,
    equipmentName: m.EquipmentName || m.equipmentName,
    status: m.Status || m.status || 'Active', // Fallback cho thiết bị chui mới thêm không mang thuộc tính default status -> là Active
    lastMaintenanceDate: m.LastMaintenanceDate || m.lastMaintenanceDate,
  }));

  // Bộ chặn lọc Filter Client-Side. Chạy Logic duyệt tìm chuỗi ở cấp độ Array Memory của trình duyệt mà không query Backend
  const filteredEquips = normalizedEquips.filter((e: any) => {
    if (!e) return false; // Sanitize rác Object null
    const term = search.toLowerCase(); // Chuẩn Hóa chuỗi Input thành Thường (lowercase) để quét khớp (includes) bỏ qua case sensitive
    const code = typeof e.equipmentCode === 'string' ? e.equipmentCode.toLowerCase() : '';
    const name = typeof e.equipmentName === 'string' ? e.equipmentName.toLowerCase() : '';
    // Cơ chế toán tử Logic: Máy hiển thị (True) nếu mã máy CODE HOẶC Tên máy NAME chứa đựng từ khóa Gõ (Term)
    return code.includes(term) || name.includes(term);
  });

  // Hàm trợ giúp (Helper) để ánh xạ trạng thái Text từ server thành Badge UI có Icon & Màu sắc động
  const getStatusDisplay = (status: string) => {
    switch (status) {
      case 'Active':
      case 'Running':
      case 'Hoạt động':
        return (
          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">
            <CheckCircle2 className="w-3.5 h-3.5 mr-1" />
            Đang hoạt động
          </span>
        );
      case 'Maintenance':
      case 'Bảo trì':
        return (
          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700">
            <AlertTriangle className="w-3.5 h-3.5 mr-1" />
            Đang bảo trì
          </span>
        );
      case 'Broken':
      case 'Hỏng hóc':
        return (
          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700">
            <AlertOctagon className="w-3.5 h-3.5 mr-1" />
            Hỏng hóc
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-neutral-100 text-neutral-700">
            {status}
          </span>
        );
    }
  };

  return (
    // <div className="space-y-6"> Áp dụng CSS của Tailwind quy định tạo hẻm rãnh 24px (1.5rem = 6*4) giữa mọi thẻ con dọc bên trong Div này
    <div className="space-y-6">
      {/* Khung Header linh hoạt Responsive (co giãn điện thoại vs laptop):
          Dùng Flexbox đẩy các cụm văn bản + nút văng ra 2 mí đối nghịch (justify-between).
          Nếu màn hình mobile (sm) hiển thị, Flex thu nhỏ gập chéo thành Column dọc (flex-col). */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Quản Lý Thiết Bị</h1>
          <p className="text-sm text-neutral-500 mt-1">
            Theo dõi tình trạng hoạt động và thông tin bảo trì của máy móc thiết bị.
          </p>
        </div>
        <button className="btn-primary w-full sm:w-auto">
          <Plus className="w-5 h-5 mr-2" />
          Thêm thiết bị mới
        </button>
      </div>

      {/* Vỏ bao Bảng dữ liệu: Đổ nền Trắng (bg-surface), kẻ viền ngoài (border), bo 12px (rounded-xl), đính mảng bóng mờ dưới đáy nổi 3D (shadow-sm) */}
      <div className="bg-surface border border-neutral-200 rounded-xl overflow-hidden shadow-sm">
        {/* Thanh bar Filter Tool trên đầu của Table (Sọc màu xám nhạt bg-neutral) */}
        <div className="p-4 border-b border-neutral-200 bg-neutral-50/50 flex flex-col sm:flex-row gap-4 justify-between">
          <div className="relative w-full sm:w-96">
            {/* Form Input TextBox Tìm kiếm. Cắm Icon Kính lúp (Search) bay trên không trung căn lề cách trái 0.75rem (absolute left-3). */}
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input
              type="text"
              placeholder="Tìm kiếm mã máy, tên thiết bị..."
              value={search}
              // Data Binding hai chiều: Truyềnn React event 'e' mỗi lúc gõ ký tự -> Bắn Update trực tiếp (setSearch) vào UseState ở dòng #6 -> render lại DOM
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearch(e.target.value)}
              // Lớp Hiệu ứng Tailwind Visual Focus: Vòng sáng xung quanh Textbox khi lấy Focus chuột (focus:ring-2 focus:ring-primary-500)
              className="w-full pl-10 pr-4 py-2 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-shadow"
            />
          </div>
          <div className="flex gap-2 w-full sm:w-auto">
            {/* Bộ Dropdown Select Listbox hỗ trợ Lọc các Máy hoạt động, bảo trì */}
            <select
              value={statusFilter}
              onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setStatusFilter(e.target.value)}
              className="w-full sm:w-auto px-3 py-2 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 bg-white"
            >
              <option value="">Tất cả trạng thái</option>
              <option value="Active">Đang hoạt động</option>
              <option value="Maintenance">Đang bảo trì</option>
              <option value="Broken">Hỏng hóc</option>
            </select>
            <button className="btn-secondary whitespace-nowrap">
              <Filter className="w-4 h-4 mr-2" />
              Lọc chi tiết
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-neutral-50 border-b border-neutral-200">
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">ID</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Mã Thiết Bị</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Tên Thiết Bị</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Trạng Thái</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Bảo Trì Gần Nhất</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {/* Tương tác Conditional Rendering: Ba nhánh rẽ logic kiểm tra hiện trạng UI */}
              {isLoading ? (
                // NHÁNH 1 - IS LOADING: Layout nếu Mạng nghẽn/Hopper chưa báo tin xong thì thả Spinner xoay xoay vòng
                <tr>
                  <td colSpan={6} className="py-8 text-center text-neutral-500">
                    <div className="flex items-center justify-center space-x-2">
                       {/* Hiệu ứng animate-spin biến viền mành thành một bánh xe sinh học Loading quay vô tận */}
                      <div className="w-5 h-5 border-2 border-primary-500 border-t-transparent rounded-full animate-spin" />
                      <span>Đang tải dữ liệu thiết bị...</span>
                    </div>
                  </td>
                </tr>
              ) : filteredEquips.length === 0 ? (
                // NHÁNH 2 - EMPTY STATE: Nếu Khách hàng gõ tìm kiếm cái gì đó rác quá (quét list không trả về con số nào -> Size Length = 0)
                // Layout rơi xuống một Empty State Fallback Panel (Hình bánh răng đen cảnh báo)
                <tr>
                  <td colSpan={6} className="py-12 text-center text-neutral-500">
                    <Settings className="w-12 h-12 text-neutral-300 mx-auto mb-3" />
                    <p className="text-lg font-medium text-neutral-900">Không có thiết bị</p>
                    <p className="text-sm">Chưa có thiết bị nào trong dây chuyền hoặc từ khóa tìm kiếm không khớp.</p>
                  </td>
                </tr>
              ) : (
                // NHÁNH 3 - RENDER GIAO DIỆN CHUẨN: Array có dữ liệu > Lặp Data Loop dùng hàm map Array
                filteredEquips.map((equip: any) => (
                  <tr key={equip.equipmentId} className="hover:bg-neutral-50 transition-colors">
                    <td className="py-3 px-4 text-sm text-neutral-900 font-medium">#{equip.equipmentId}</td>
                    <td className="py-3 px-4 text-sm font-mono text-neutral-600">{equip.equipmentCode}</td>
                    <td className="py-3 px-4 text-sm text-neutral-900 font-medium">{equip.equipmentName}</td>
                    <td className="py-3 px-4">
                      {getStatusDisplay(equip.status)}
                    </td>
                    <td className="py-3 px-4 text-sm text-neutral-500">
                      {equip.lastMaintenanceDate ? new Date(equip.lastMaintenanceDate).toLocaleDateString('vi-VN') : '-'}
                    </td>
                    <td className="py-3 px-4 text-right">
                      <div className="flex items-center justify-end space-x-2">
                        <button className="p-1.5 text-neutral-400 hover:text-primary-600 hover:bg-primary-50 rounded-lg transition-colors" title="Cập nhật bảo trì">
                          <PenTool className="w-4 h-4" />
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
