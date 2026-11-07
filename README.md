# 🌐 PortManager — macOS Status Bar Mini App

Một ứng dụng native macOS siêu nhẹ (viết bằng **Swift & SwiftUI**) chạy trên thanh Menu Bar (Status Bar), giúp quản lý, tra cứu và giải phóng port đang bị chiếm dụng bởi các tiến trình (Node.js, Python, Docker, Go, Java, Postgres,...) một cách tức thì.

---

## ✨ Tính Năng Nổi Bật

1. **Hiển thị trực tiếp trên Status Bar (Menu Bar)**:
   - Icon mạng (`network`) tinh tế trên status bar.
   - Nhấp vào là popup/popover xuất hiện ngay lập tức, nhấp ra ngoài tự động đóng.
   - Chạy ngầm dạng Utility App (`LSUIElement = true`), không làm rác thanh Dock.
   - Tiêu thụ cực kỳ ít RAM (~40MB) so với các giải pháp Electron nặng nề (>300MB).

2. **Tra cứu Port nhanh chóng (Port Inspector)**:
   - Input field nhập số port (ví dụ: `3000`, `8080`, `5173`, `5432`,...). Tự động focus con trỏ để gõ ngay khi mở.
   - Nút **View** (hoặc chỉ cần bấm phím **Enter / Return** trên bàn phím).
   - Các nút **Presets** tiện lợi (`3000`, `5173`, `8000`, `8080`, `5432`, `27017`, `3306`, `6379`) để tra cứu nhanh chỉ với 1 click.

3. **Hiển thị chi tiết Tiến trình & Related Processes**:
   - **Thông tin chi tiết**: Tên tiến trình (Process Name), PID, User sở hữu, Socket address (VD: `127.0.0.1:3000`), CPU & RAM usage.
   - **Full Command & Path**: Hiển thị toàn bộ câu lệnh thực thi kèm nút **Copy Command** tiện lợi.
   - **Related Programs (Parent / Launcher)**: Nhận diện tiến trình cha khởi chạy (ví dụ: `npm run dev`, `cargo run`, `zsh`, `python manage.py`,...) kèm PPID và câu lệnh cha.
   - **Child Processes**: Tự động dò tìm các tiến trình worker con (child workers, cluster threads).

4. **Nút Kill & Kill All**:
   - **Nút Kill từng tiến trình**: Dừng ngay lập tức PID được chọn.
   - **Nút Kill Tree**: Tiêu diệt toàn bộ cây tiến trình (Parent + Child workers) nếu tiến trình được spawn từ script hoặc cluster.
   - **Nút Kill All**: Nút màu đỏ nổi bật ở trên cùng giúp tiêu diệt **tất cả** các tiến trình đang chiếm dụng port đó chỉ với 1 cú click. Tự động kiểm tra lại trạng thái để báo xanh "Port is FREE".

5. **Tab "All Active Ports" (Mở Rộng)**:
   - Quét và liệt kê tất cả các cổng mạng đang lắng nghe (Listening Ports) trên máy Mac của bạn.
   - Hỗ trợ ô tìm kiếm/lọc theo số port, tên app hoặc user.
   - Nút **Inspect** để chuyển sang xem chi tiết hoặc **Kill** nhanh ngay trong danh sách.

---

## 🚀 Hướng Dẫn Sử Dụng & Khởi Chạy

### Cách 1: Khởi chạy ngay lập tức
Ứng dụng hiện **đã được build sẵn** thành file `PortManager.app` trong thư mục này:
```bash
./run.sh
```
Sau khi chạy, bạn sẽ thấy biểu tượng mạng trên thanh Menu Bar góc trên bên phải màn hình macOS!

### Cách 2: Cài đặt vào thư mục `/Applications` của macOS
Nếu muốn cài đặt vào Applications để Spotlight, Raycast hoặc Launchpad có thể mở bất cứ lúc nào:
```bash
./install.sh
```

### Cách 3: Tự động khởi chạy cùng macOS (Launch at Login)
Vào **System Settings** -> **General** -> **Login Items** -> Thêm `PortManager.app`.

---

## 🛠 Cách Build Lại từ Mã Nguồn (Nâng Cao)

Dự án sử dụng Swift Package Manager (SPM) tiêu chuẩn:

```bash
# Build release và đóng gói thành PortManager.app
./build_app.sh
```

Cấu trúc thư mục mã nguồn:
```
portmanager/
├── Package.swift                     # Khai báo Swift Package
├── build_app.sh                      # Script build release + bundle .app + codesign
├── run.sh                            # Script khởi chạy hoặc restart app
├── install.sh                        # Script copy app vào /Applications
├── generate_icon.py                  # Script sinh file AppIcon.icns
├── PortManager.app/                  # Bundle ứng dụng macOS hoàn chỉnh
└── Sources/
    ├── App/
    │   ├── AppDelegate.swift         # Quản lý NSStatusItem & NSPopover
    │   └── main.swift                # Điểm khởi chạy NSApplication
    ├── Models/
    │   └── ProcessModel.swift        # Cấu trúc dữ liệu Process & RelatedProcess
    ├── Services/
    │   └── PortScannerService.swift  # Logic quét port lsof, ps, pgrep và Darwin kill
    ├── ViewModels/
    │   └── PortManagerViewModel.swift# Quản lý state, filter, toast & actions
    └── Views/
        ├── MainView.swift            # Giao diện chính (Header, Search, Presets, Results)
        ├── ProcessCardView.swift     # Thẻ hiển thị từng tiến trình & cây cha/con
        └── ActivePortsView.swift     # Danh sách quét tất cả listening ports
```

