import { useQuery } from '@tanstack/react-query';
import { productionBatchesApi } from '@/services/api';
import { X, ClipboardList, Info, AlertTriangle, CheckCircle2 } from 'lucide-react';

interface BatchLogsModalProps {
  batchId: number;
  batchNumber: string;
  onClose: () => void;
}

export default function BatchLogsModal({ batchId, batchNumber, onClose }: BatchLogsModalProps) {
  const { data: logsResponse, isLoading, isError } = useQuery({
    queryKey: ['batchLogs', batchId],
    queryFn: () => productionBatchesApi.getProcessLogs(batchId),
  });

  const logs = (logsResponse as any)?.data || logsResponse || [];

  const parseParameters = (data?: string) => {
    if (!data) return null;
    try {
      const parsed = JSON.parse(data);
      // Flatten rawInputs if exists (Drying step structure)
      if (parsed.rawInputs) return parsed.rawInputs;
      return parsed;
    } catch (e) {
      return null;
    }
  };

  const getStatusBadge = (status?: string) => {
    const s = (status || '').toLowerCase();
    if (s === 'passed' || s === 'approved' || s === 'success') {
      return <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-green-100 text-green-700 uppercase">Đạt</span>;
    }
    if (s === 'failed' || s === 'rejected') {
      return <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-red-100 text-red-700 uppercase">Không Đạt</span>;
    }
    return <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-100 text-amber-700 uppercase">{status || 'N/A'}</span>;
  };

  return (
    <div className="fixed inset-0 bg-neutral-900/60 backdrop-blur-sm z-[100] flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl w-full max-w-5xl max-h-[90vh] flex flex-col shadow-2xl overflow-hidden border border-neutral-200">
        {/* Header */}
        <div className="px-6 py-4 border-b border-neutral-100 flex items-center justify-between bg-neutral-50/50">
          <div>
            <h3 className="text-xl font-bold text-neutral-900 flex items-center gap-2">
              <ClipboardList className="w-5 h-5 text-primary-600" />
              Chi tiết nhật ký sản xuất
            </h3>
            <p className="text-sm text-neutral-500 mt-0.5">
              Mã mẻ: <span className="font-mono font-semibold text-primary-700">{batchNumber}</span>
            </p>
          </div>
          <button 
            onClick={onClose}
            className="p-2 hover:bg-neutral-200 rounded-full transition-colors"
          >
            <X className="w-6 h-6 text-neutral-400" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {isLoading ? (
            <div className="flex flex-col items-center justify-center py-20">
              <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-600 mb-4"></div>
              <p className="text-neutral-500 animate-pulse">Đang tải dữ liệu vận hành...</p>
            </div>
          ) : isError ? (
            <div className="flex flex-col items-center justify-center py-20 text-red-500 bg-red-50 rounded-xl border border-red-100">
              <AlertTriangle className="w-12 h-12 mb-2" />
              <p className="font-semibold">Lỗi khi tải dữ liệu!</p>
              <p className="text-xs mt-2 text-red-400">
                {(logsResponse as any)?.message || (logsResponse as any)?.error || 'Lỗi không xác định từ máy chủ'}
              </p>
              <button onClick={() => onClose()} className="mt-4 text-sm underline">Quay lại</button>
            </div>
          ) : logs.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-neutral-400">
              <Info className="w-16 h-16 mb-4 opacity-20" />
              <p className="text-lg font-medium">Chưa có dữ liệu nhật ký cho mẻ này.</p>
              <p className="text-sm">Vận hành viên chưa bắt đầu thực hiện các công đoạn.</p>
            </div>
          ) : (
            <div className="space-y-8">
              {logs.map((log: any, idx: number) => {
                const params = parseParameters(log.parametersData);
                const stepName = log.step?.stepName || log.stepName || `Công đoạn ${idx + 1}`;
                
                return (
                  <div key={log.logId} className="relative pl-8 border-l-2 border-neutral-100 last:border-l-0 pb-2">
                    {/* Timeline dot */}
                    <div className="absolute -left-[9px] top-0 w-4 h-4 rounded-full bg-primary-600 border-4 border-white shadow-sm" />
                    
                    <div className="card !p-0 overflow-hidden border-neutral-200 shadow-sm hover:shadow-md transition-shadow">
                      <div className="bg-neutral-50 px-4 py-3 border-b border-neutral-100 flex flex-wrap items-center justify-between gap-3">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-lg bg-primary-100 text-primary-700 flex items-center justify-center font-bold text-sm">
                            {log.step?.stepNumber || idx + 1}
                          </div>
                          <div>
                            <h4 className="font-bold text-neutral-900">{stepName}</h4>
                            <p className="text-[10px] text-neutral-500 uppercase tracking-wider font-semibold">
                            {log.endTime ? new Date(log.endTime).toLocaleString('vi-VN', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit', year: 'numeric' }) : 'Đang thực hiện...'}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3">
                          {getStatusBadge(log.resultStatus)}
                          {log.isDeviation && (
                            <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-red-100 text-red-700 uppercase flex items-center gap-1">
                              <AlertTriangle className="w-3 h-3" /> Sai lệch
                            </span>
                          )}
                        </div>
                      </div>

                      <div className="p-4">
                        {params ? (
                          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                            {Object.entries(params).map(([key, value]) => {
                              // Skip complex objects like arrays of materials (handle separately)
                              if (Array.isArray(value) || (typeof value === 'object' && value !== null)) return null;
                              
                              const keyLabels: Record<string, string> = {
                                temperature: 'Nhiệt độ (°C)',
                                humidity: 'Độ ẩm (%)',
                                pressure: 'Áp lực (Pa)',
                                phongPhaChe: 'Phòng pha chế',
                                checkTime: 'TG Kiểm tra',
                                canIW2: 'Cân IW2-60',
                                canPMA: 'Cân PMA-5000',
                                dungCuCan: 'Dụng cụ cân',
                                veSinhPhong: 'Vệ sinh phòng',
                                veSinhMay: 'Vệ sinh máy',
                                veSinhDungCu: 'Vệ sinh dụng cụ',
                                tgBatDau: 'TG Bắt đầu',
                                tgKetThuc: 'TG Kết thúc',
                                duPhamLoSo: 'Dư phẩm lô số',
                                tyTrongGo: 'Tỷ trọng gõ (hạt khô)',
                                nhietDo: 'Nhiệt độ phòng',
                                doAm: 'Độ ẩm phòng',
                                apLuc: 'Áp lực phòng',
                                tgCaiDat: 'TG Trộn (cài đặt)',
                                tocDoCaiDat: 'Tốc độ (cài đặt)',
                                tgThucTe: 'TG Trộn (thực tế)',
                                tocDoThucTe: 'Tốc độ (thực tế)',
                                tyTrong: 'Tỷ trọng hạt',
                                slDongGoiKg: 'SL Đóng gói (kg)',
                                slSilicagel: 'SL Silicagel',
                                checkPhong: 'Kiểm tra phòng',
                                checkMay: 'Kiểm tra máy',
                                checkDungCu: 'Kiểm tra dụng cụ',
                                nhietDoKhiVao: 'Nhiệt độ khí vào',
                                nhietDoKhiRa: 'Nhiệt độ khí ra',
                                tgSayCaiDat: 'Thời gian sấy (cài đặt)',
                                tocDoGio: 'Tốc độ gió',
                                inputMoisture: 'Độ ẩm đầu vào',
                                moistureAt: 'Độ ẩm tại',
                                wetWeight: 'KL trước sấy',
                                dryWeight: 'KL sau sấy',
                                netWeight: 'KL tịnh',
                                lossPercent: 'Hao hụt (%)'
                              };

                              return (
                                <div key={key} className="flex flex-col border-b border-neutral-50 pb-2">
                                  <span className="text-[10px] font-bold text-neutral-400 uppercase tracking-tight">
                                    {keyLabels[key] || key}
                                  </span>
                                  <span className="text-sm text-neutral-800 font-medium">
                                    {typeof value === 'boolean' ? (value ? 'Đạt/Sạch' : 'Không đạt') : String(value || '-')}
                                  </span>
                                </div>
                              );
                            })}
                          </div>
                        ) : (
                          <p className="text-sm text-neutral-400 italic">Không có thông số chi tiết.</p>
                        )}

                        {/* Special handling for Materials list in Weighing/Mixing */}
                        {params?.materials && (
                          <div className="mt-6 pt-4 border-t border-neutral-100">
                            <h5 className="text-xs font-bold text-neutral-900 mb-3 flex items-center gap-2">
                              <CheckCircle2 className="w-3.5 h-3.5 text-green-600" />
                              Danh sách nguyên liệu / thành phần
                            </h5>
                            <div className="bg-neutral-50 rounded-xl overflow-hidden border border-neutral-200">
                              <table className="w-full text-xs text-left">
                                <thead className="bg-neutral-100 text-neutral-600">
                                  <tr>
                                    <th className="px-3 py-2">Nguyên liệu</th>
                                    <th className="px-3 py-2">Phiếu KN / Lô</th>
                                    <th className="px-3 py-2 text-right">Khối lượng (kg)</th>
                                  </tr>
                                </thead>
                                <tbody className="divide-y divide-neutral-200">
                                  {Array.isArray(params.materials) ? (
                                    params.materials.map((m: any, i: number) => (
                                      <tr key={i} className="hover:bg-white transition-colors">
                                        <td className="px-3 py-2 font-medium">{m.materialName || m.name}</td>
                                        <td className="px-3 py-2 font-mono text-[10px]">{m.phieuKN || m.lotNumber || '-'}</td>
                                        <td className="px-3 py-2 text-right font-bold text-primary-700">{m.actual}</td>
                                      </tr>
                                    ))
                                  ) : (
                                    Object.entries(params.materials).map(([name, data]: [string, any], i: number) => (
                                      <tr key={i} className="hover:bg-white transition-colors">
                                        <td className="px-3 py-2 font-medium">{name}</td>
                                        <td className="px-3 py-2 font-mono text-[10px]">{data.phieuKN || '-'}</td>
                                        <td className="px-3 py-2 text-right font-bold text-primary-700">{data.actual}</td>
                                      </tr>
                                    ))
                                  )}
                                </tbody>
                              </table>
                            </div>
                          </div>
                        )}

                        {/* Mixing specific actual materials */}
                        {params?.khoiLuongThucTe && typeof params.khoiLuongThucTe === 'object' && (
                           <div className="mt-6 pt-4 border-t border-neutral-100">
                            <h5 className="text-xs font-bold text-neutral-900 mb-3 flex items-center gap-2">
                              <CheckCircle2 className="w-3.5 h-3.5 text-blue-600" />
                              Dữ liệu khối lượng thực tế (Trộn)
                            </h5>
                            <div className="bg-neutral-50 rounded-xl overflow-hidden border border-neutral-200">
                              <table className="w-full text-xs text-left">
                                <thead className="bg-neutral-100 text-neutral-600">
                                  <tr>
                                    <th className="px-3 py-2">Mã / Tên</th>
                                    <th className="px-3 py-2 text-right">Khối lượng thực tế</th>
                                  </tr>
                                </thead>
                                <tbody className="divide-y divide-neutral-200">
                                  {Object.entries(params.khoiLuongThucTe).map(([key, val]: [string, any], i) => (
                                    <tr key={i} className="hover:bg-white transition-colors">
                                      <td className="px-3 py-2 font-medium">{key}</td>
                                      <td className="px-3 py-2 text-right font-bold text-blue-700">{String(val)}</td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>
                            </div>
                           </div>
                        )}
                        
                        {log.notes && (
                          <div className="mt-4 p-3 bg-amber-50 rounded-lg border border-amber-100">
                            <p className="text-[10px] font-bold text-amber-800 uppercase mb-1">Ghi chú / Sai lệch:</p>
                            <p className="text-xs text-amber-900 whitespace-pre-wrap">{log.notes}</p>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-neutral-100 bg-neutral-50 flex justify-between items-center">
          <div className="text-[10px] text-neutral-400 uppercase font-semibold tracking-widest">
            Hệ thống quản lý sản xuất GMP-WHO
          </div>
          <button 
            onClick={onClose}
            className="btn-primary"
          >
            Đóng cửa sổ
          </button>
        </div>
      </div>
    </div>
  );
}
