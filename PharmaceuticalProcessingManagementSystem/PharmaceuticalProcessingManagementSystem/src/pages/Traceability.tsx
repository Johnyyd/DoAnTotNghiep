// Placeholder - Full traceability report implementation
import { useState } from 'react';
import { Search } from 'lucide-react';

export default function Traceability() {
  const [batchNumber, setBatchNumber] = useState('');
  const [result, setResult] = useState<any>(null);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    // Mock result - will call API /traceability/backward/:batchNumber
    setResult({
      batchNumber,
      finishedGood: {
        name: 'Paracetamol 500mg Box',
        batchNumber,
        producedDate: '2025-03-08',
        quantity: 10000,
      },
      rawMaterials: [
        {
          name: 'Paracetamol API',
          batchNumber: 'BATCH-API-2025-001',
          quantity: 5000000,
          supplier: 'API Supplier Co.',
          qcStatus: 'Passed',
        },
        {
          name: 'Microcrystalline Cellulose',
          batchNumber: 'BATCH-EXC-2025-001',
          quantity: 1500000,
          supplier: 'Excipient Corp',
          qcStatus: 'Passed',
        },
      ],
    });
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Truy Xuất Nguồn Gốc</h1>
      </div>

      {/* Search form */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <form onSubmit={handleSearch} className="flex gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Nhập mã lô thành phẩm (ví dụ: FG-BATCH-001)..."
              value={batchNumber}
              onChange={(e) => setBatchNumber(e.target.value)}
              className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-gmp-primary focus:border-transparent"
            />
          </div>
          <button
            type="submit"
            className="px-6 py-3 bg-gmp-primary text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
          >
            Truy xuất
          </button>
        </form>
      </div>

      {/* Result */}
      {result && (
        <div className="space-y-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              Kết quả truy xuất cho lô: <span className="text-gmp-primary">{result.batchNumber}</span>
            </h2>

            <div className="grid md:grid-cols-2 gap-6 mb-6">
              <div className="bg-gmp-background rounded-lg p-4">
                <h3 className="font-medium text-gray-900 mb-2">Thành phẩm</h3>
                <div className="space-y-2 text-sm">
                  <p><span className="font-medium">Tên:</span> {result.finishedGood.name}</p>
                  <p><span className="font-medium">Lô:</span> {result.finishedGood.batchNumber}</p>
                  <p><span className="font-medium">Ngày sản xuất:</span> {result.finishedGood.producedDate}</p>
                  <p><span className="font-medium">Số lượng:</span> {result.finishedGood.quantity.toLocaleString()}</p>
                </div>
              </div>
            </div>

            <div>
              <h3 className="font-medium text-gray-900 mb-3">Nguyên liệu đầu vào</h3>
              <div className="space-y-3">
                {result.rawMaterials.map((mat: any, idx: number) => (
                  <div key={idx} className="border border-gray-200 rounded-lg p-4">
                    <div className="flex items-center justify-between mb-2">
                      <h4 className="font-medium text-gray-900">{mat.name}</h4>
                      <span className={`px-2 py-1 text-xs font-semibold rounded-full ${
                        mat.qcStatus === 'Passed'
                          ? 'bg-green-100 text-green-800'
                          : 'bg-red-100 text-red-800'
                      }`}>
                        QC: {mat.qcStatus}
                      </span>
                    </div>
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm text-gray-600">
                      <div>
                        <span className="font-medium">Lô nguyên liệu:</span>
                        <p className="text-gray-900">{mat.batchNumber}</p>
                      </div>
                      <div>
                        <span className="font-medium">Nhà cung cấp:</span>
                        <p className="text-gray-900">{mat.supplier}</p>
                      </div>
                      <div>
                        <span className="font-medium">Lượng dùng:</span>
                        <p className="text-gray-900">{mat.quantity.toLocaleString()}</p>
                      </div>
                      <div>
                        <span className="font-medium">Trạng thái:</span>
                        <p className="text-gray-900">Đạt chuẩn</p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="mt-6 flex justify-end">
              <button className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 mr-3">
                Xem chi tiết đầy đủ (PDF)
              </button>
              <button className="px-4 py-2 bg-gmp-primary text-white rounded-lg hover:bg-blue-700">
                Xuất báo cáo truy xuất
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Instructions */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Hướng dẫn sử dụng</h3>
        <ul className="space-y-2 text-sm text-gray-600">
          <li className="flex items-start">
            <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
            <span>Nhập mã lô thành phẩm (như trong tem/nhãn đóng gói)</span>
          </li>
          <li className="flex items-start">
            <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
            <span>Hệ thống sẽ hiển thị toàn bộ chuỗi nguyên liệu đã sử dụng</span>
          </li>
          <li className="flex items-start">
            <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
            <span>Báo cáo đầy đủ có thể xuất ra PDF cho mục đích audit</span>
          </li>
          <li className="flex items-start">
            <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
            <span>Truy xuất ngược (Backward) và xuôi (Forward) đều được hỗ trợ</span>
          </li>
        </ul>
      </div>
    </div>
  );
}
