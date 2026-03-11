// Placeholder - Will implement full Production Order management
export default function ProductionOrders() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Lệnh Sản Xuất (Production Orders)</h1>
        <button className="flex items-center px-4 py-2 bg-gmp-primary text-white rounded-lg hover:bg-blue-700 transition-colors">
          Tạo lệnh mới
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-12 text-center">
        <div className="max-w-md mx-auto">
          <div className="w-16 h-16 bg-gmp-background rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-gmp-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
            </svg>
          </div>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Production Order Management</h3>
          <p className="text-gray-600 mb-6">
            Trang này sẽ được phát triển đầy đủ với:
          </p>
          <ul className="text-left text-sm text-gray-600 space-y-2 mb-6">
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>Danh sách lệnh sản xuất với state machine (Draft → Approved → InProcess → Hold → Completed)</span>
            </li>
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>Tính toán nguyên liệu cần thiết dựa trên BOM</span>
            </li>
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>Approve với Digital Signature (nhập lại mật khẩu)</span>
            </li>
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>Hold/Resume với lý do (reason code)</span>
            </li>
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>Complete với final signature và tạo Finished Goods Batch</span>
            </li>
          </ul>
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 text-sm text-yellow-800">
            <strong>GMP Critical:</strong> Không cho phép chuyển trạng thái tùy tiện. Transition phải qua validation nghiêm ngặt.
          </div>
        </div>
      </div>
    </div>
  );
}
