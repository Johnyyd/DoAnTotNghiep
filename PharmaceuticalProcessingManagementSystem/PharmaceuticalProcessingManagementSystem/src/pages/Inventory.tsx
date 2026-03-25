import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { inventoryApi } from '@/services/api';
import { Search, PackageOpen, Filter } from 'lucide-react';

export default function Inventory() {
  const [search, setSearch] = useState('');

  const { data: lots, isLoading } = useQuery({
    queryKey: ['inventory-lots'],
    queryFn: () => inventoryApi.getLots(),
  });

  const lotsData = Array.isArray(lots) ? lots : (lots as any)?.data ?? [];

  const normalizedLots = lotsData.map((m: any) => ({
    lotId: m.lotId,
    materialId: m.materialId,
    materialName: m.material?.materialName ?? m.materialName ?? 'Unknown Material',
    lotNumber: m.lotNumber,
    quantityCurrent: m.quantityCurrent,
    manufactureDate: m.manufactureDate,
    expiryDate: m.expiryDate,
    qcStatus: m.qcstatus ?? m.qcStatus ?? 'Quarantine',
  }));

  const filteredLots = normalizedLots.filter((lot: any) => {
    if (!lot) return false;
    const term = search.toLowerCase();
    const materialName = typeof lot.materialName === 'string' ? lot.materialName.toLowerCase() : '';
    const lotNumber = typeof lot.lotNumber === 'string' ? lot.lotNumber.toLowerCase() : '';
    return materialName.includes(term) || lotNumber.includes(term);
  });

  const getStatusInfo = (status: string) => {
    switch (status) {
      case 'Released':
        return { label: 'Đã duyệt (Released)', classes: 'bg-green-100 text-green-700' };
      case 'Rejected':
        return { label: 'Từ chối (Rejected)', classes: 'bg-red-100 text-red-700' };
      case 'Quarantine':
      default:
        return { label: 'Kiểm dịch (Quarantine)', classes: 'bg-yellow-100 text-yellow-700' };
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center space-y-4 sm:space-y-0">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900">Quản Lý Tồn Kho (Lô Nguyên Liệu)</h1>
          <p className="text-sm text-neutral-500 mt-1">
            Theo dõi danh sách các lô nguyên vật liệu và trạng thái kiểm tra chất lượng (QC).
          </p>
        </div>
      </div>

      <div className="bg-surface border border-neutral-200 rounded-xl overflow-hidden shadow-sm">
        <div className="p-4 border-b border-neutral-200 bg-neutral-50/50 flex flex-col sm:flex-row gap-4 justify-between">
          <div className="relative w-full sm:w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-400" />
            <input
              type="text"
              placeholder="Tìm kiếm theo mã lô, tên nguyên liệu..."
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
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">ID Lô</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Mã Lô</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Nguyên vật liệu</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600 text-right">Tồn kho hiện tại</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Ngày sản xuất</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Hạn sử dụng</th>
                <th className="py-3 px-4 text-sm font-semibold text-neutral-600">Trạng thái (QC)</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-200">
              {isLoading ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-neutral-500">
                    <div className="flex items-center justify-center space-x-2">
                      <div className="w-5 h-5 border-2 border-primary-500 border-t-transparent rounded-full animate-spin" />
                      <span>Đang tải dữ liệu lô hàng...</span>
                    </div>
                  </td>
                </tr>
              ) : filteredLots.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-neutral-500">
                    <PackageOpen className="w-12 h-12 text-neutral-300 mx-auto mb-3" />
                    <p className="text-lg font-medium text-neutral-900">Không có dữ liệu</p>
                    <p className="text-sm">Chưa có lô kiểm kho nào hoặc từ khóa tìm kiếm không khớp.</p>
                  </td>
                </tr>
              ) : (
                filteredLots.map((lot: any) => (
                  <tr key={lot.lotId} className="hover:bg-neutral-50 transition-colors">
                    <td className="py-3 px-4 text-sm text-neutral-900 font-medium">#{lot.lotId}</td>
                    <td className="py-3 px-4 text-sm font-mono text-neutral-600">{lot.lotNumber}</td>
                    <td className="py-3 px-4 text-sm text-neutral-900 font-medium">{lot.materialName}</td>
                    <td className="py-3 px-4 text-sm text-neutral-900 text-right font-mono">{lot.quantityCurrent?.toLocaleString() ?? 0}</td>
                    <td className="py-3 px-4 text-sm text-neutral-500">
                      {lot.manufactureDate ? new Date(lot.manufactureDate).toLocaleDateString('vi-VN') : '-'}
                    </td>
                    <td className="py-3 px-4 text-sm text-neutral-500">
                      {lot.expiryDate ? new Date(lot.expiryDate).toLocaleDateString('vi-VN') : '-'}
                    </td>
                    <td className="py-3 px-4">
                      {(() => {
                        const info = getStatusInfo(lot.qcStatus);
                        return (
                          <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${info.classes}`}>
                            {info.label}
                          </span>
                        );
                      })()}
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
