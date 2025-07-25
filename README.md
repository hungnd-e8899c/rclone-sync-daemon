# RClone sync daemon

Đây là daemon để đồng bộ hóa dữ liệu hai chiều. Nó được thiết kế trên giả định là
mọi thay đổi được thao tác trên máy cá nhân (rclone mount). 

## Thiết kế

Cài đặt:
- Rclone mount sẽ gắn remote vào thư mục cục bộ (vd: `OneDrive`).
- Rclone sync để đồng bộ hóa dữ liệu từ remote sang local lần đầu tiên (vd: `OneDriveCache`).

Đồng bộ remote sang local:
- Dùng inotify để theo dõi thay đổi trong thư mục cục bộ.
- Nếu có thay đổi, nó sẽ đồng bộ hóa dữ liệu từ remote sang local.
- Lần mount đầu tiên sẽ đồng bộ toàn bộ dữ liệu từ remote sang local.

Đồng bộ local sang remote:
- Tương tự, theo dõi thay đổi trong thư mục cục bộ.
- Nếu có thay đổi, nó sẽ đồng bộ hóa dữ liệu từ local sang remote.

Truy cập, chỉnh sửa:
- Người dùng sửa toàn bộ trên thư mục cục bộ (vd: `OneDriveCache`).
- Daemon sẽ tự động đồng bộ hóa dữ liệu từ local sang remote và ngược lại.
