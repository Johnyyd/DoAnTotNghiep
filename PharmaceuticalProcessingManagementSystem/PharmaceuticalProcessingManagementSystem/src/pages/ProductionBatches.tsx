// Placeholder - Will implement Batch execution for shop floor workers
export default function ProductionBatches() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Mẻ Sản Xuất (Production Batches)</h1>
        <button className="flex items-center px-4 py-2 bg-gmp-primary text-white rounded-lg hover:bg-blue-700 transition-colors">
          Tạo mẻ mới
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-12 text-center">
        <div className="max-w-md mx-auto">
          <div className="w-16 h-16 bg-gmp-background rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-gmp-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19.428 15.428a2 2 0 00-1.022-.547l-2.384-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z" />
            </svg>
          </div>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Production Batch Execution</h3>
          <p className="text-gray-600 mb-6">
            Trang này sẽ được phát triển đầy đủ cho Mobile/Tablet App dành cho công nhân:
          </p>
          <ul className="text-left text-sm text-gray-600 space-y-2 mb-6">
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>Scan barcode để tìm Production Batch</span>
            </li>
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>Xem công thức và BOM định mức</span>
            </li>
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>Bắt đầu/Kết thúc từng công đoạn trong Routing</span>
            </li>
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>Nhập số liệu thực tế (quantity, time, notes)</span>
            </li>
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>QC in-process với cảnh báo deviation ±5%</span>
            </li>
          </ul>
          <div className="bg-purple-50 border border-purple-200 rounded-lg p-4 text-sm text-purple-800">
            <strong>Mobile-first:</strong> Giao diện được tối ưu cho Tablet, hỗ trợ offline-first với sync khi có network.
          </div>
        </div>
      </div>
    </div>
  );
}
