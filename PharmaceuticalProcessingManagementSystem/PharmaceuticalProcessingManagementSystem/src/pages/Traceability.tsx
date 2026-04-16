import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { certificatesApi, inventoryApi } from '@/services/api';
import { Search, Info, FileCheck2 } from 'lucide-react';
import axios from 'axios';

export default function Traceability() {
  const [batchNumberInput, setBatchNumberInput] = useState('');
  const [searchBatch, setSearchBatch] = useState<string | null>(null);

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
    }
  };

  const result: any = (traceData as any)?.data || traceData;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Truy xuất nguồn gốc</h1>
        <p className="text-neutral-500 mt-1">Tra cứu lô thành phẩm và các nguyên liệu đầu vào</p>
      </div>

      <div className="card print:hidden">
        <form onSubmit={handleSearch} className="flex gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input type="text" placeholder="Nhập mã lô thành phẩm (ví dụ: B26-007-02)..." value={batchNumberInput} onChange={(e) => setBatchNumberInput(e.target.value)} className="input pl-10" required />
          </div>
          <button type="submit" disabled={isLoading} className="btn-primary">{isLoading ? 'Đang truy xuất...' : 'Truy xuất'}</button>
        </form>
      </div>

      {isLoading && (
        <div className="flex items-center justify-center p-12 card text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600 mx-auto mb-4"></div>
          <p className="text-neutral-500">Đang phân tích dữ liệu truy xuất...</p>
        </div>
      )}

      {isError && (
        <div className="card border-red-200 bg-red-50 text-red-700">
          <h3 className="font-bold mb-2">Lỗi truy xuất</h3>
          <p>{(error as Error).message || 'Không thể truy xuất dữ liệu.'}</p>
        </div>
      )}

      {!isLoading && !isError && searchBatch && !result && (
        <div className="card text-center py-12">
          <Info className="w-12 h-12 text-neutral-300 mx-auto mb-4" />
          <p className="text-neutral-500">Không tìm thấy dữ liệu cho mã lô <strong>{searchBatch}</strong>.</p>
        </div>
      )}

      {!isLoading && !isError && result && (
        <div className="card space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold text-neutral-900">Lô thành phẩm: {result.finishedGoodBatchNumber}</h2>
            <span className="text-sm text-neutral-500">Sản phẩm: {result.productName || '-'}</span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-3 text-sm">
            <div className="p-3 rounded-lg bg-neutral-50 border border-neutral-200"><p className="text-neutral-500">Mã lệnh sản xuất</p><p className="font-semibold text-neutral-900">{result.productionOrderId ?? '-'}</p></div>
            <div className="p-3 rounded-lg bg-neutral-50 border border-neutral-200"><p className="text-neutral-500">Số lượng thành phẩm</p><p className="font-semibold text-neutral-900">{result.quantityProduced?.toLocaleString?.() ?? result.quantityProduced ?? '-'}</p></div>
            <div className="p-3 rounded-lg bg-neutral-50 border border-neutral-200"><p className="text-neutral-500">Số nguyên liệu</p><p className="font-semibold text-neutral-900">{result.rawMaterials?.length ?? 0}</p></div>
            <div className="p-3 rounded-lg bg-neutral-50 border border-neutral-200">
              <p className="text-neutral-500">Giấy kiểm nghiệm lô thành phẩm</p>
              <a className="text-primary-600 hover:underline inline-flex items-center font-medium mt-1" href={result.finishedCertificateUrl || certificatesApi.getLotCertificateUrl(result.finishedGoodBatchNumber)} target="_blank" rel="noreferrer">
                <FileCheck2 className="w-4 h-4 mr-1" /> Xem
              </a>
            </div>
          </div>

          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Mã nguyên liệu</th>
                  <th>Tên nguyên liệu</th>
                  <th>Lô nguyên liệu</th>
                  <th>Khối lượng đã dùng</th>
                  <th>Số lượng lô</th>
                  <th>Tỉ lệ (%)</th>
                  <th>Giấy kiểm nghiệm</th>
                </tr>
              </thead>
              <tbody>
                {(result.rawMaterials ?? []).length === 0 ? (
                  <tr><td colSpan={7} className="text-center py-4 text-neutral-500">Không có dữ liệu nguyên liệu cho lô này.</td></tr>
                ) : (
                  (result.rawMaterials ?? []).map((mat: any, idx: number) => (
                    <tr key={`${mat.materialCode}-${idx}`}>
                      <td><code className="text-xs bg-neutral-100 px-2 py-1 rounded font-mono text-primary-600">{mat.materialCode}</code></td>
                      <td>{mat.materialName}</td>
                      <td>{mat.inventoryLotNumber}</td>
                      <td>{Number(mat.quantityUsed ?? 0).toLocaleString()} {mat.uom ?? ''}</td>
                      <td>{mat.lotQuantityCurrent == null ? '-' : `${Number(mat.lotQuantityCurrent).toLocaleString()} ${mat.uom ?? ''}`}</td>
                      <td>{Number(mat.ratioPercent ?? 0).toFixed(2)}</td>
                      <td>
                        <a className="text-primary-600 hover:underline inline-flex items-center" href={certificatesApi.getMaterialCertificateUrl(mat.materialCode)} target="_blank" rel="noreferrer">
                          <FileCheck2 className="w-4 h-4 mr-1" /> Xem
                        </a>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
