# Sơ Đồ Quy Trình Nghiệp Vụ - GMP WHO System

Dựa trên bộ codebase hiện tại, dưới đây là hệ thống các sơ đồ mô phỏng kiến trúc, luồng dữ liệu, tương tác tác nhân và quy trình nghiệp vụ thực tế.

## 1. Sơ đồ Use Case (Tác nhân & Phân quyền)

Bản đồ phân tầng đặc quyền của các tác nhân (Actors) đối với các Module trong hệ thống. Hệ thống xoay quanh nguyên tắc "Phân quyền tối thiểu" (Least Privilege) của GMP.

```mermaid
flowchart LR
    Admin([Admin])
    Manager([Giám Đốc / Quản lý])
    Operator([Nhân viên vận hành])
    QC([Kiểm soát])
    Auditor([Thanh tra])

    subgraph System [Hệ thống Quản lý GMP-WHO]
        UC1(Quản lý Tài khoản)
        UC2(Quản lý Nguyên liệu & Tồn kho)
        UC3(Quản lý Công thức)
        UC4(Lập Lệnh Sản xuất)
        UC5(Duyệt / Tạm Ngưng Lệnh SX)
        UC6(Thực thi Sản xuất)
        UC7(Quản lý Sai lệch / Deviation)
        UC8(Truy xuất Nguồn gốc)
        UC9(Theo dõi Nhật ký / Audit)
    end

    Admin --> UC1
    Manager --> UC2
    Manager --> UC3
    Manager --> UC4
    Manager --> UC5
    QC --> UC5
    Operator --> UC6
    Operator --> UC7
    QC --> UC8
    Auditor --> UC9
    QC --> UC9
```

---

## 2. Sơ đồ Trạng thái (Luồng Đời sống của Lệnh Sản Xuất)

Quy trình biến đổi logic từ lúc lên kế hoạch (Draft) cho tới khi chốt sổ (Completed). Mọi thao tác chuyển trạng thái quan trọng đều buộc phải qua xác thực chữ ký (Mã PIN).

```mermaid
stateDiagram-v2
    [*] --> Draft : Lập lệnh sản xuất mới (Bộ phận Kế hoạch / Giám đốc)
    Draft --> Approved : Duyệt Lệnh (Quản lý / QC yêu cầu mã PIN)
    Approved --> InProcess : Cấp phát xuống xưởng / Bắt đầu mẻ
    InProcess --> Hold : Phát hiện sự cố / Tạm ngưng (Ghi nhận lý do)
    Hold --> InProcess : Mở lại lệnh sản xuất
    InProcess --> Completed : Hoàn tất 100% công đoạn
    Completed --> [*]

    state InProcess {
      [*] --> Step1_Weighing : Mobile App - Cân nguyên liệu
      Step1_Weighing --> Step2_Mixing : Ký xác nhận & Check Sai lệch BOM (<5%)
      Step2_Mixing --> Step3_Drying : Ký xác nhận công đoạn Trộn
      Step3_Drying --> Finalizing : Ký xác nhận công đoạn Sấy
      Finalizing --> [*] : Hoàn thành Mẻ (Batch Process)
    }
```

---

## 3. Sơ đồ Tuần tự (Sequence Diagram - Thực thi công đoạn Mobile)

Ví dụ điển hình nhất trong quá trình vận hành sản xuất: Một Công nhân (Operator) thực hiện công đoạn Cân nguyên liệu.

```mermaid
sequenceDiagram
    actor Operator as Công Nhân (Operator)
    participant MobileApp as App Vận hành (Flutter)
    participant ApiServer as Backend API (.NET 8)
    participant Database as Storage (SQL Server)

    Operator->>MobileApp: Mở Lệnh SX & Chọn "Công đoạn Cân"
    MobileApp->>ApiServer: GET /api/production-batches/{id}
    ApiServer-->>MobileApp: Trả về Data Batch & Định mức (BOM)
    Operator->>MobileApp: Nhập khối lượng cân thực tế
    MobileApp->>MobileApp: Tính toán Sai Lệch (Actual vs BOM)
    
    alt Lệch quá 5% (Deviation)
        MobileApp-->>Operator: CẢNH BÁO ĐỎ: Vượt quá biên độ 5%
        Operator->>MobileApp: Bấm "Chấp nhận Lỗi" & Nhập lý do (Failed)
    else Sai lệch ≤ 5% (Hợp lệ)
        MobileApp->>MobileApp: Cờ trạng thái = Passed
    end

    Operator->>MobileApp: Bấm "Ký Xác Nhận Số"
    MobileApp-->>Operator: Pop-up yêu cầu Nhập PIN
    Operator->>MobileApp: Nhập PIN cá nhân (Signature)
    
    MobileApp->>ApiServer: POST /api/batchprocesslogs (Gửi Payload & Token Auth)
    ApiServer->>ApiServer: Validate Token & Ghi nhận Audit Interceptor
    ApiServer->>Database: Lưu Log tiến trình vào DB
    Database-->>ApiServer: 200 OK (Đã lưu)
    ApiServer-->>MobileApp: Trả về thành công
    MobileApp-->>Operator: Hoàn thành công đoạn & Chuyển bước tiếp theo
```

---

## 4. Kiến trúc và Luồng Dữ Liệu Hệ Thống (Data Flow)

Cấu trúc kiến trúc vật lý và sơ đồ giao tiếp Client-Server của toàn hệ thống.

```mermaid
flowchart TD
    subgraph Frontend_Layer [Lớp Giao Diện Khách Hàng]
        Web(React Web Admin\nTruy xuất, Lập kế hoạch)
        Mob(Flutter Mobile App\nVận hành kho xưởng)
    end

    subgraph Backend_Layer [Lớp Dịch Vụ - .NET 8]
        Auth(JWT Authentication\nAuthorization Filter)
        Controller(API Controllers\nĐịnh tuyến Endpoint)
        Service(Business Logic Services\nXử lý nghiệp vụ & Audit Trail)
    end

    subgraph Database_Layer [Lớp Dữ Liệu]
        SQL[(SQL Server 2022\nEF Core ORM)]
    end

    %% Giao tiếp Front-Back
    Web -- "REST HTTP (Port 8080)" --> Auth
    Mob -- "REST HTTP (Port 8081)" --> Auth

    %% Luồng đi nội bộ Backend
    Auth -- "Pass" --> Controller
    Controller --> Service
    
    %% Tác vụ nghiệp vụ cụ thể
    Service -. "Tạo Công Thức (BOM) & Lệnh" .-> SQL
    Service -. "Lưu Hành Động (Audit Trail Logging)" .-> SQL
    Service -. "Check E-Signature & Lưu Deviation" .-> SQL
    
    %% Truy xuất phản hồi
    SQL -. "Xuất Cây Nguồn Gốc (Traceability)" .-> Web
```
