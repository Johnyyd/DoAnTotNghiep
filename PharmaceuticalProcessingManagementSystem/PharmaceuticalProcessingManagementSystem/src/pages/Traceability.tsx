import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { inventoryApi } from '@/services/api';
import { Search, Info, Package, FileText, CheckCircle, XCircle } from 'lucide-react';

export default function Traceability() {
  const [batchNumberInput, setBatchNumberInput] = useState('');
  const [searchBatch, setSearchBatch] = useState<string | null>(null);

  const { data: traceData, isLoading, isError, error } = useQuery({
    queryKey: ['traceability', searchBatch],
    queryFn: () => inventoryApi.traceBackward(searchBatch!),
    enabled: !!searchBatch, // Only run the query when searchBatch has a value
    retry: false, // Don't retry on 404
  });

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (batchNumberInput.trim()) {
      setSearchBatch(batchNumberInput.trim());
    }
  };

  // @ts-ignore
  const result: any = traceData?.data || traceData; // Extract the actual data payload

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Truy Xuất Nguồn Gốc</h1>
          <p className="text-neutral-500 mt-1">Truy xuất ngược từ Mẻ Thành Phẩm ra các Nguyên Liệu cấu thành</p>
        </div>
      </div>

      {/* Search form */}
      <div className="card">
        <form onSubmit={handleSearch} className="flex gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Nhập mã lô thành phẩm (ví dụ: FB-001)..."
              value={batchNumberInput}
              onChange={(e) => setBatchNumberInput(e.target.value)}
              className="input pl-10"
              required
            />
          </div>
          <button
            type="submit"
            disabled={isLoading}
            className="btn-primary"
          >
            {isLoading ? 'Đang truy xuất...' : 'Truy xuất'}
          </button>
        </form>
      </div>

      {/* States: Loading, Error, Empty, Success */}
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

      {/* Result UI */}
      {!isLoading && !isError && result && (
        <div className="space-y-6">
          <div className="card border-primary-100 overflow-hidden">
            <div className="bg-primary-50 px-6 py-4 border-b border-primary-100 flex items-center justify-between">
              <h2 className="text-lg font-bold text-primary-900">
                Lô Thành Phẩm: <span className="text-primary-600 ml-2">{result.finishedGoodBatchNumber}</span>
              </h2>
              <div className="px-3 py-1 bg-white rounded-full text-sm font-medium text-primary-700 shadow-sm">
                Tìm thấy {result.rawMaterials?.length || 0} nguyên liệu
              </div>
            </div>

            <div className="p-6">
              {/* Product Info Summary */}
              <div className="flex items-start space-x-4 mb-8 bg-neutral-50 p-4 rounded-xl">
                <div className="p-3 bg-white rounded-lg shadow-sm">
                  <Package className="w-6 h-6 text-primary-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-neutral-900">{result.productName || 'Tên Sản Phẩm Đang Cập Nhật'}</h3>
                  <div className="flex items-center mt-2 space-x-6 text-sm text-neutral-600">
                    <span><strong>Order ID:</strong> {result.productionOrderId || '-'}</span>
                    <span><strong>Số lượng sx:</strong> {result.quantityProduced?.toLocaleString() || '-'}</span>
                  </div>
                </div>
              </div>

              {/* Raw Materials Tree */}
              <div>
                <h3 className="font-bold text-neutral-900 mb-4 flex items-center">
                  <FileText className="w-5 h-5 mr-2 text-primary-600" />
                  Nguyên Liệu Đầu Vào (Truy xuất ngược)
                </h3>
                
                <div className="space-y-4 relative border-l-2 border-primary-100 ml-3 pl-6">
                  {result.rawMaterials && result.rawMaterials.length > 0 ? (
                    result.rawMaterials.map((mat: any, idx: number) => (
                      <div key={idx} className="relative">
                        {/* Connecting Line Dot */}
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
                      Không có lịch sử nhập liệu nguyên liệu cho Mẻ này.
                    </div>
                  )}
                </div>
              </div>

              {/* Action Buttons */}
              <div className="mt-8 pt-6 border-t border-neutral-200 flex justify-end space-x-3">
                <button className="btn-ghost flex items-center text-primary-700 font-medium">
                  <FileText className="w-4 h-4 mr-2" />
                  Xem báo cáo PDF đầy đủ
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Instructions */}
      {!result && !isLoading && !isError && (
        <div className="card bg-gradient-to-br from-primary-50 to-white border-primary-100">
          <h3 className="text-lg font-bold text-primary-900 mb-4 flex items-center">
            <Info className="w-5 h-5 mr-2" /> Hướng dẫn truy xuất (Tuân thủ GMP)
          </h3>
          <ul className="space-y-3 text-sm text-neutral-700">
            <li className="flex items-start">
              <span className="w-6 h-6 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center font-bold text-xs mr-3 shrink-0">1</span>
              <span>Nhập mã lô thành phẩm <strong>(Finished Good Batch)</strong> tương ứng có trên nhãn sản phẩm.</span>
            </li>
            <li className="flex items-start">
              <span className="w-6 h-6 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center font-bold text-xs mr-3 shrink-0">2</span>
              <span>Hệ thống sẽ tra cứu toàn bộ <strong>Material Usages</strong> liên kết với mẻ sản xuất đó.</span>
            </li>
            <li className="flex items-start">
              <span className="w-6 h-6 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center font-bold text-xs mr-3 shrink-0">3</span>
              <span>Kết quả trả về danh sách đầy đủ <strong>nguyên liệu đầu vào, mã lô của nhà cung cấp, và thời gian sử dụng</strong>. Có thể dùng cho đợt thanh tra cục quản lý Dược.</span>
            </li>
          </ul>
        </div>
      )}
    </div>
  );
}
