import http.server
import socketserver
import socket
import os
import sys
from urllib.parse import quote

# Configuration
PORT = 8000
DIRECTORY = "ipa"  # Changed to relative path

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

class CustomHTTPHandler(http.server.SimpleHTTPRequestHandler):
    """Custom HTTP handler that serves a beautiful mobile-friendly interface"""
    
    def do_GET(self):
        """Handle GET requests with custom HTML for root path"""
        if self.path == '/' or self.path == '/index.html':
            self.send_custom_html()
        else:
            # Serve files normally
            super().do_GET()
    
    def send_custom_html(self):
        """Generate and send custom HTML page with large icons and copy buttons"""
        local_ip = get_local_ip()
        base_url = f"http://{local_ip}:{PORT}"
        
        # Find all IPA files
        files = [f for f in os.listdir('.') if f.endswith('.ipa')]
        
        # Generate HTML
        html = f"""
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>📦 IPA 文件下载</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
            color: #333;
        }}
        
        .container {{
            max-width: 600px;
            margin: 0 auto;
        }}
        
        .header {{
            text-align: center;
            color: white;
            margin-bottom: 30px;
        }}
        
        .header h1 {{
            font-size: 32px;
            margin-bottom: 10px;
        }}
        
        .header p {{
            font-size: 16px;
            opacity: 0.9;
        }}
        
        .file-card {{
            background: white;
            border-radius: 16px;
            padding: 24px;
            margin-bottom: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            transition: transform 0.2s;
        }}
        
        .file-card:active {{
            transform: scale(0.98);
        }}
        
        .file-icon {{
            font-size: 80px;
            text-align: center;
            margin-bottom: 16px;
        }}
        
        .file-name {{
            font-size: 18px;
            font-weight: 600;
            color: #333;
            text-align: center;
            margin-bottom: 20px;
            word-break: break-all;
        }}
        
        .url-container {{
            background: #f5f5f5;
            border-radius: 12px;
            padding: 16px;
            margin-bottom: 16px;
            position: relative;
        }}
        
        .url-text {{
            font-size: 14px;
            color: #666;
            word-break: break-all;
            line-height: 1.6;
            font-family: 'Courier New', monospace;
        }}
        
        .button-group {{
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
        }}
        
        .button {{
            padding: 16px;
            border: none;
            border-radius: 12px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }}
        
        .copy-btn {{
            background: #667eea;
            color: white;
        }}
        
        .copy-btn:active {{
            background: #5568d3;
        }}
        
        .download-btn {{
            background: #48bb78;
            color: white;
        }}
        
        .download-btn:active {{
            background: #38a169;
        }}
        
        .toast {{
            position: fixed;
            top: 20px;
            left: 50%;
            transform: translateX(-50%) translateY(-100px);
            background: rgba(0,0,0,0.9);
            color: white;
            padding: 16px 24px;
            border-radius: 12px;
            font-size: 16px;
            opacity: 0;
            transition: all 0.3s;
            z-index: 1000;
            pointer-events: none;
        }}
        
        .toast.show {{
            opacity: 1;
            transform: translateX(-50%) translateY(0);
        }}
        
        .empty-state {{
            background: white;
            border-radius: 16px;
            padding: 60px 24px;
            text-align: center;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }}
        
        .empty-state-icon {{
            font-size: 80px;
            margin-bottom: 20px;
        }}
        
        .empty-state-text {{
            font-size: 18px;
            color: #666;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📦 IPA 文件下载</h1>
            <p>轻触复制按钮复制下载链接</p>
        </div>
        
"""
        
        if files:
            for filename in files:
                file_url = f"{base_url}/{quote(filename)}"
                html += f"""
        <div class="file-card">
            <div class="file-icon">📱</div>
            <div class="file-name">{filename}</div>
            <div class="url-container">
                <div class="url-text" id="url-{hash(filename)}">{file_url}</div>
            </div>
            <div class="button-group">
                <button class="button copy-btn" onclick="copyUrl('{file_url}', this)">
                    <span>📋</span>
                    <span>复制链接</span>
                </button>
                <a href="{quote(filename)}" download style="text-decoration: none;">
                    <button class="button download-btn">
                        <span>⬇️</span>
                        <span>下载</span>
                    </button>
                </a>
            </div>
        </div>
"""
        else:
            html += """
        <div class="empty-state">
            <div class="empty-state-icon">📭</div>
            <div class="empty-state-text">暂无 IPA 文件</div>
        </div>
"""
        
        html += """
    </div>
    
    <div class="toast" id="toast">✅ 链接已复制到剪贴板</div>
    
    <script>
        function copyUrl(url, button) {
            // Create temporary input element
            const input = document.createElement('input');
            input.value = url;
            input.style.position = 'fixed';
            input.style.top = '-1000px';
            document.body.appendChild(input);
            
            // Select and copy
            input.select();
            input.setSelectionRange(0, 99999); // For mobile devices
            
            try {
                document.execCommand('copy');
                showToast();
                
                // Visual feedback
                const originalText = button.innerHTML;
                button.innerHTML = '<span>✅</span><span>已复制!</span>';
                button.style.background = '#48bb78';
                
                setTimeout(() => {
                    button.innerHTML = originalText;
                    button.style.background = '#667eea';
                }, 2000);
            } catch (err) {
                alert('复制失败，请手动复制');
            }
            
            document.body.removeChild(input);
        }
        
        function showToast() {
            const toast = document.getElementById('toast');
            toast.classList.add('show');
            
            setTimeout(() => {
                toast.classList.remove('show');
            }, 2000);
        }
        
        // Prevent zoom on double tap for buttons
        document.querySelectorAll('.button').forEach(button => {
            let lastTap = 0;
            button.addEventListener('touchend', (e) => {
                const currentTime = new Date().getTime();
                const tapLength = currentTime - lastTap;
                if (tapLength < 500 && tapLength > 0) {
                    e.preventDefault();
                }
                lastTap = currentTime;
            });
        });
    </script>
</body>
</html>
"""
        
        # Send response
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', len(html.encode('utf-8')))
        self.end_headers()
        self.wfile.write(html.encode('utf-8'))

def run_server():
    # Get the script's directory and navigate to ipa folder
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    ipa_dir = os.path.join(project_root, DIRECTORY)
    
    if not os.path.exists(ipa_dir):
        os.makedirs(ipa_dir)
    
    os.chdir(ipa_dir)
    
    # Allow address reuse to avoid "Address already in use" errors
    socketserver.TCPServer.allow_reuse_address = True
    
    with socketserver.ThreadingTCPServer(("", PORT), CustomHTTPHandler) as httpd:
        local_ip = get_local_ip()
        base_url = f"http://{local_ip}:{PORT}"
        
        print(f"\n{'='*60}")
        print(f"✅ IPA 文件服务器已启动!")
        print(f"{'='*60}")
        print(f"📱 请确保手机和电脑连接同一个 Wi-Fi")
        print(f"")
        print(f"👉 在 iPhone Safari 浏览器访问:")
        print(f"")
        print(f"   {base_url}")
        print(f"")
        print(f"💡 提示:")
        print(f"   - 点击复制按钮一键复制下载链接")
        print(f"   - 界面已针对 iPhone 优化")
        print(f"   - 支持大图标方便点击")
        print(f"")
        print(f"📂 IPA 文件目录: {ipa_dir}")
        print(f"")
        print(f"按 Ctrl+C 停止服务器")
        print(f"{'='*60}\n")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n\n服务器已停止。")

if __name__ == "__main__":
    run_server()
