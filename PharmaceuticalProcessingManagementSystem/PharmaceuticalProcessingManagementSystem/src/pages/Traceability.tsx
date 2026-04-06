import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { inventoryApi } from '@/services/api';
import { Search, Info, Package, FileText, CheckCircle, XCircle, Image } from 'lucide-react';
import axios from 'axios';

export default function Traceability() {
  const [batchNumberInput, setBatchNumberInput] = useState('');
  const [searchBatch, setSearchBatch] = useState<string | null>(null);
  const [showCertificate, setShowCertificate] = useState(false);

  const { data: traceData, isLoading, isError, error } = useQuery({
    queryKey: ['traceability', searchBatch],
    queryFn: async () => {
      try {
        return await inventoryApi.traceBackward(searchBatch!);
      } catch (err) {
        if (axios.isAxiosError(err) && err.response?.status === 404) {
          return null;
        }
        throw err;
      }
    },
    enabled: !!searchBatch,
    retry: false,
  });

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (batchNumberInput.trim()) {
      setSearchBatch(batchNumberInput.trim());
      setShowCertificate(false);
    }
  };

  const result: any = (traceData as any)?.data || traceData;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Truy Xuất Nguồn Gốc</h1>
          <p className="text-neutral-500 mt-1">Truy xuất ngược từ lô thành phẩm về nguyên liệu đầu vào</p>
        </div>
      </div>

      <div className="card print:hidden">
        <form onSubmit={handleSearch} className="flex gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Nhập mã lô thành phẩm (ví dụ: FB-001)..."
              value={batchNumberInput}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setBatchNumberInput(e.target.value)}
              className="input pl-10"
              required
            />
          </div>
          <button type="submit" disabled={isLoading} className="btn-primary">
            {isLoading ? 'Đang truy xuất...' : 'Truy xuất'}
          </button>
        </form>
      </div>

      {isLoading && (
        <div className="flex items-center justify-center p-12 card text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600 mx-auto mb-4"></div>
          <p className="text-neutral-500">Đang phân tích chuỗi dữ liệu truy xuất...</p>
        </div>
      )}

      {isError && (
        <div className="card border-red-200 bg-red-50 text-red-700">
          <div className="flex items-center mb-2">
            <XCircle className="w-5 h-5 mr-2" />
            <h3 className="font-bold">Lỗi Truy Xuất</h3>
          </div>
          <p>{(error as Error).message || 'Không tìm thấy thông tin truy xuất cho mã lô này.'}</p>
        </div>
      )}

      {!isLoading && !isError && searchBatch && !result && (
        <div className="card text-center py-12">
          <Info className="w-12 h-12 text-neutral-300 mx-auto mb-4" />
          <p className="text-neutral-500">Không có dữ liệu cho mã lô <strong>{searchBatch}</strong></p>
        </div>
      )}

      {!isLoading && !isError && result && (
        <div className="space-y-6">
          <div className="card border-primary-100 overflow-hidden">
            <div className="bg-primary-50 px-6 py-4 border-b border-primary-100 flex items-center justify-between">
              <h2 className="text-lg font-bold text-primary-900">
                Lô thành phẩm: <span className="text-primary-600 ml-2">{result.finishedGoodBatchNumber}</span>
              </h2>
              <div className="px-3 py-1 bg-white rounded-full text-sm font-medium text-primary-700 shadow-sm">
                Tìm thấy {result.rawMaterials?.length || 0} nguyên liệu
              </div>
            </div>

            <div className="p-6">
              <div className="flex items-start space-x-4 mb-8 bg-neutral-50 p-4 rounded-xl">
                <div className="p-3 bg-white rounded-lg shadow-sm">
                  <Package className="w-6 h-6 text-primary-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-neutral-900">{result.productName || 'Tên sản phẩm đang cập nhật'}</h3>
                  <div className="flex items-center mt-2 space-x-6 text-sm text-neutral-600">
                    <span><strong>Order ID:</strong> {result.productionOrderId || '-'}</span>
                    <span><strong>Số lượng sản xuất:</strong> {result.quantityProduced?.toLocaleString() || '-'}</span>
                  </div>
                </div>
              </div>

              <div>
                <h3 className="font-bold text-neutral-900 mb-4 flex items-center">
                  <FileText className="w-5 h-5 mr-2 text-primary-600" />
                  Nguyên liệu đầu vào (truy xuất ngược)
                </h3>

                <div className="space-y-4 relative border-l-2 border-primary-100 ml-3 pl-6">
                  {result.rawMaterials && result.rawMaterials.length > 0 ? (
                    result.rawMaterials.map((mat: any, idx: number) => (
                      <div key={idx} className="relative">
                        <div className="absolute -left-[29px] top-4 w-3 h-3 bg-white border-2 border-primary-500 rounded-full" />

                        <div className="bg-white border border-neutral-200 hover:border-primary-300 transition-colors rounded-xl p-4 shadow-sm">
                          <div className="flex items-center justify-between mb-3">
                            <h4 className="font-semibold text-neutral-900">
                              {mat.materialName} <span className="text-neutral-400 font-normal text-sm">({mat.materialCode})</span>
                            </h4>
                            <span className="inline-flex items-center px-2 py-1 bg-green-50 text-green-700 text-xs font-semibold rounded-full">
                              <CheckCircle className="w-3 h-3 mr-1" /> OK
                            </span>
                          </div>

                          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                            <div>
                              <p className="text-neutral-500 mb-1">Lot / Batch (NCC)</p>
                              <p className="font-medium text-neutral-900">{mat.inventoryLotNumber}</p>
                            </div>
                            <div>
                              <p className="text-neutral-500 mb-1">Lượng sử dụng</p>
                              <p className="font-medium text-neutral-900">{mat.quantityUsed?.toLocaleString()} {mat.uom}</p>
                            </div>
                            <div>
                              <p className="text-neutral-500 mb-1">Sử dụng lúc</p>
                              <p className="font-medium text-neutral-900">{mat.usedAt ? new Date(mat.usedAt).toLocaleString('vi-VN') : '-'}</p>
                            </div>
                            <div>
                              <p className="text-neutral-500 mb-1">Người nhập liệu</p>
                              <p className="font-medium text-neutral-900">User ID: {mat.usedBy || 'Hệ thống'}</p>
                            </div>
                          </div>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="text-sm text-neutral-500 italic">
                      Không có lịch sử nhập liệu nguyên liệu cho mẻ này.
                    </div>
                  )}
                </div>
              </div>

              <div className="mt-8 pt-6 border-t border-neutral-200 flex justify-end space-x-3 print:hidden">
                <button onClick={() => setShowCertificate(true)} className="btn-ghost flex items-center text-primary-700 font-medium">
                  <Image className="w-4 h-4 mr-2" />
                  Xem giấy chứng nhận
                </button>
                <button onClick={() => window.print()} className="btn-ghost flex items-center text-primary-700 font-medium">
                  <FileText className="w-4 h-4 mr-2" />
                  Xuất báo cáo PDF / In
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {!result && !isLoading && !isError && (
        <div className="card bg-gradient-to-br from-primary-50 to-white border-primary-100">
          <h3 className="text-lg font-bold text-primary-900 mb-4 flex items-center">
            <Info className="w-5 h-5 mr-2" /> Hướng dẫn truy xuất (Tuân thủ GMP)
          </h3>
          <ul className="space-y-3 text-sm text-neutral-700">
            <li className="flex items-start">
              <span className="w-6 h-6 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center font-bold text-xs mr-3 shrink-0">1</span>
              <span>Nhập mã lô thành phẩm <strong>(Finished Good Batch)</strong> tương ứng trên nhãn sản phẩm.</span>
            </li>
            <li className="flex items-start">
              <span className="w-6 h-6 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center font-bold text-xs mr-3 shrink-0">2</span>
              <span>Hệ thống tra cứu toàn bộ <strong>Material Usages</strong> liên kết với mẻ sản xuất đó.</span>
            </li>
            <li className="flex items-start">
              <span className="w-6 h-6 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center font-bold text-xs mr-3 shrink-0">3</span>
              <span>Kết quả trả về nguyên liệu đầu vào, mã lô nhà cung cấp và thời gian sử dụng để phục vụ thanh tra GMP.</span>
            </li>
          </ul>
        </div>
      )}

      {showCertificate && (
        <div className="fixed inset-0 bg-neutral-900 bg-opacity-60 z-50 flex items-center justify-center p-4">
          <div className="bg-surface rounded-2xl shadow-2xl w-full max-w-5xl max-h-[90vh] overflow-hidden">
            <div className="flex items-center justify-between px-6 py-4 border-b border-neutral-200">
              <h3 className="text-lg font-bold text-neutral-900">Giấy chứng nhận lô sản xuất</h3>
              <button onClick={() => setShowCertificate(false)} className="btn-ghost text-sm">Đóng</button>
            </div>
            <div className="p-4 overflow-auto max-h-[calc(90vh-72px)] bg-neutral-50">
              <img src="/certificate.jpg" alt="Giấy chứng nhận" className="w-full h-auto rounded-lg border border-neutral-200 bg-white" />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

