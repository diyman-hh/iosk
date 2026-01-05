import wda
import time
import sys
from loguru import logger

# 配置 Loguru 日志
logger.remove()
logger.add(sys.stderr, format="<green>{time:HH:mm:ss}</green> | <level>{message}</level>")

def test_single_device():
    # 1. 连接设备
    # 默认连接本地 USB 映射的 8100 端口
    # 如果是 WiFi 模式，这里改为 "http://192.168.x.x:8100"
    DEVICE_URL = "http://localhost:8100"
    
    logger.info(f"正在尝试连接设备: {DEVICE_URL} ...")
    try:
        c = wda.Client(DEVICE_URL)
        device_info = c.info
        logger.success(f"连接成功! 设备信息: {device_info}")
    except Exception as e:
        logger.error(f"连接失败: {e}")
        logger.warning("请检查: 1.手机是否连接 2.tidevice是否运行 3.WDA是否在手机上启动")
        return

    # 2. 启动 TikTok
    # Bundle ID: 
    # 国际版 TikTok: com.zhiliaoapp.musically
    # 美区/特定版可能是: com.ss.iphone.ugc.Aweme (也就是抖音, 视ipa版本而定)
    TIKTOK_BUNDLE_ID = "com.zhiliaoapp.musically" 
    
    logger.info(f"正在启动 APP: {TIKTOK_BUNDLE_ID}")
    try:
        s = c.session(TIKTOK_BUNDLE_ID)
    except Exception as e:
        logger.error(f"启动 APP 失败: {e}")
        logger.info("尝试使用抖音 Bundle ID (com.ss.iphone.ugc.Aweme) ...")
        TIKTOK_BUNDLE_ID = "com.ss.iphone.ugc.Aweme"
        s = c.session(TIKTOK_BUNDLE_ID)

    # 等待启动广告
    logger.info("APP 已启动，等待 5 秒加载...")
    time.sleep(5)
    
    # 3. 获取屏幕大小
    window_size = c.window_size()
    width = window_size.width
    height = window_size.height
    logger.info(f"屏幕分辨率: {width}x{height}")

    # 4. 执行滑动 (模拟刷视频)
    for i in range(3):
        logger.info(f"执行第 {i+1}/3 次滑动...")
        # 从下往上滑 (x, y) 坐标
        # start: 屏幕中心偏下, end: 屏幕中心偏上
        c.swipe(width * 0.5, height * 0.8, width * 0.5, height * 0.2, 0.2)
        
        # 模拟观看时长 (随机 2-4 秒)
        time.sleep(3)
        
    # 5. 截图 (可选)
    # logger.info("正在截图...")
    # c.screenshot().save("debug_screenshot.png")
    
    # 6. 回到桌面 (结束)
    logger.info("测试结束，回到桌面")
    c.home()

if __name__ == "__main__":
    test_single_device()
