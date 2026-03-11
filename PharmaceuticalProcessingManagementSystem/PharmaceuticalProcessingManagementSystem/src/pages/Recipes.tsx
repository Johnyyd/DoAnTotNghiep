// Placeholder - Will implement full CRUD with BOM and Routing management
export default function Recipes() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Quản Lý Công Thức & BOM</h1>
        <button className="flex items-center px-4 py-2 bg-gmp-primary text-white rounded-lg hover:bg-blue-700 transition-colors">
          Thêm công thức mới
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-12 text-center">
        <div className="max-w-md mx-auto">
          <div className="w-16 h-16 bg-gmp-background rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-gmp-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Công Thức & BOM Management</h3>
          <p className="text-gray-600 mb-6">
            Trang này sẽ được phát triển đầy đủ với:
          </p>
          <ul className="text-left text-sm text-gray-600 space-y-2 mb-6">
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>Danh sách công thức với trạng thái Draft/Approved</span>
            </li>
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>BOM đệ quy nhiều cấp với drag-and-drop</span>
            </li>
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>Recipe Routing với các bước QC</span>
            </li>
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>Digital Signature khi Approve</span>
            </li>
            <li className="flex items-start">
              <span className="w-2 h-2 bg-gmp-primary rounded-full mt-1.5 mr-2 flex-shrink-0" />
              <span>Version control cho Recipe</span>
            </li>
          </ul>
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 text-sm text-blue-800">
            <strong>GMP Note:</strong> Recipe chỉ được edit ở trạng thái Draft. Khi Approved, snapshot sẽ được lưu vào ProductionOrder.
          </div>
        </div>
      </div>
    </div>
  );
}
