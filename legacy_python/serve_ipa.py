import http.server
import socketserver
import socket
import os
import sys

# Configuration
PORT = 8000
DIRECTORY = "ipa"

def get_local_ip():
    """Attempts to retrieve the local IP address connected to the network."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Doesn't handle a connection, just used to determine the interface
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip

def run_server():
    # Change to the project directory/ipa
    os.chdir(os.path.join(os.path.dirname(__file__), DIRECTORY))
    
    handler = http.server.SimpleHTTPRequestHandler
    
    # Allow address reuse to avoid "Address already in use" errors
    socketserver.TCPServer.allow_reuse_address = True
    
    with socketserver.ThreadingTCPServer(("", PORT), handler) as httpd:
        local_ip = get_local_ip()
        base_url = f"http://{local_ip}:{PORT}"
        
        print(f"\n{'='*50}")
        print(f"✅ 文件服务器已启动!")
        print(f"{'='*50}")
        print(f"请确保手机和电脑连接同一个 Wi-Fi。\n")
        print(f"👉 手机 Safari 访问地址: {base_url}\n")
        
        print("📂 当前可下载文件:")
        files = [f for f in os.listdir('.') if f.endswith('.ipa')]
        for f in files:
            print(f"   ⬇️  {f}:")
            print(f"       {base_url}/{f}")
            print("-" * 30)
            
        print(f"\n按 Ctrl+C 停止服务器")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n服务器已停止。")

if __name__ == "__main__":
    run_server()
