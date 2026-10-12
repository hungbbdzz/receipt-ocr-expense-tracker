import os
from PIL import Image, ImageDraw, ImageFont

def create_receipt(filename, merchant, address, date_str, items, subtotal, tax_name, tax_val, total_str, cash_str, change_str):
    width = 700
    height = 980
    
    # White/Off-white thermal receipt background
    img = Image.new("RGB", (width, height), color=(252, 252, 250))
    draw = ImageDraw.Draw(img)
    
    # Draw receipt subtle shadow border
    draw.rectangle([(20, 20), (width - 20, height - 20)], outline=(210, 210, 210), width=2)
    
    # Fonts
    font_bold_large = ImageFont.truetype("C:\\Windows\\Fonts\\arialbd.ttf", 36)
    font_bold_med = ImageFont.truetype("C:\\Windows\\Fonts\\arialbd.ttf", 26)
    font_med = ImageFont.truetype("C:\\Windows\\Fonts\\arial.ttf", 24)
    font_small = ImageFont.truetype("C:\\Windows\\Fonts\\arial.ttf", 20)
    font_mono = ImageFont.truetype("C:\\Windows\\Fonts\\consola.ttf", 24)
    
    y = 50
    # Merchant Name
    draw.text((width / 2, y), merchant, fill=(20, 20, 20), font=font_bold_large, anchor="mm")
    y += 45
    # Address
    draw.text((width / 2, y), address, fill=(70, 70, 70), font=font_small, anchor="mm")
    y += 30
    draw.text((width / 2, y), f"Ngay: {date_str}", fill=(70, 70, 70), font=font_small, anchor="mm")
    y += 35
    
    # Divider
    draw.line([(40, y), (width - 40, y)], fill=(120, 120, 120), width=2)
    y += 30
    
    # Header
    draw.text((50, y), "Mat hang", fill=(40, 40, 40), font=font_bold_med)
    draw.text((width - 50, y), "Thanh tien", fill=(40, 40, 40), font=font_bold_med, anchor="ra")
    y += 40
    
    # Items
    for name, price in items:
        draw.text((50, y), name, fill=(30, 30, 30), font=font_med)
        draw.text((width - 50, y), price, fill=(30, 30, 30), font=font_med, anchor="ra")
        y += 42
        
    y += 10
    # Dashed divider
    draw.line([(40, y), (width - 40, y)], fill=(180, 180, 180), width=1)
    y += 25
    
    if subtotal:
        draw.text((50, y), "Tam tinh:", fill=(80, 80, 80), font=font_med)
        draw.text((width - 50, y), subtotal, fill=(80, 80, 80), font=font_med, anchor="ra")
        y += 38
        
    if tax_name and tax_val:
        draw.text((50, y), tax_name, fill=(80, 80, 80), font=font_med)
        draw.text((width - 50, y), tax_val, fill=(80, 80, 80), font=font_med, anchor="ra")
        y += 38
        
    draw.line([(40, y), (width - 40, y)], fill=(60, 60, 60), width=2)
    y += 35
    
    # Total - HIGHLIGHTED BOLD
    draw.text((50, y), "TONG CONG:", fill=(0, 0, 0), font=font_bold_large)
    draw.text((width - 50, y), total_str, fill=(0, 0, 0), font=font_bold_large, anchor="ra")
    y += 55
    
    # Cash & Change
    if cash_str:
        draw.text((50, y), "Khach dua:", fill=(80, 80, 80), font=font_med)
        draw.text((width - 50, y), cash_str, fill=(80, 80, 80), font=font_med, anchor="ra")
        y += 38
    if change_str:
        draw.text((50, y), "Tien thua:", fill=(80, 80, 80), font=font_med)
        draw.text((width - 50, y), change_str, fill=(80, 80, 80), font=font_med, anchor="ra")
        y += 45
        
    draw.line([(40, y), (width - 40, y)], fill=(150, 150, 150), width=1)
    y += 35
    draw.text((width / 2, y), "CAM ON QUY KHACH VA HEN GAP LAI!", fill=(80, 80, 80), font=font_small, anchor="mm")
    y += 30
    draw.text((width / 2, y), "--- Xin giu lai hoa don de doi tra ---", fill=(130, 130, 130), font=font_small, anchor="mm")
    
    img.save(filename, "PNG", dpi=(300, 300))
    print(f"Generated: {filename}")

os.makedirs("test_receipts", exist_ok=True)

# 1. Highlands Coffee
create_receipt(
    filename="test_receipts/receipt_highlands.png",
    merchant="HIGHLANDS COFFEE",
    address="123 Nguyen Huu Tho, Quan Hai Chau, Da Nang",
    date_str="12/10/2026 14:35",
    items=[
        ("1. Phin Sua Da (L)", "39.000"),
        ("2. Tra Sen Vang (M)", "45.000"),
        ("3. Banh mi que pate", "19.000")
    ],
    subtotal="103.000",
    tax_name="VAT (8%):",
    tax_val="8.240",
    total_str="111.240 VND",
    cash_str="200.000 VND",
    change_str="88.760 VND"
)

# 2. WinMart
create_receipt(
    filename="test_receipts/receipt_winmart.png",
    merchant="WINMART+",
    address="KTX Dai hoc VKU, Ngu Hanh Son, Da Nang",
    date_str="2026-10-10 08:45",
    items=[
        ("Sua tuoi tiet trung TH 1L", "36.000"),
        ("Mi Hao Hao tom chua cay (x5)", "22.000"),
        ("Xuc xich Duc CP 500g", "42.000")
    ],
    subtotal=None,
    tax_name=None,
    tax_val=None,
    total_str="100.000 d",
    cash_str="100.000 d",
    change_str="0 d"
)

# 3. Circle K
create_receipt(
    filename="test_receipts/receipt_circle_k.png",
    merchant="CIRCLE K",
    address="45 Le Duan, Quan Hai Chau, Da Nang",
    date_str="08/10/2026 21:15",
    items=[
        ("Ca phe sua da Circle K", "20.000"),
        ("Banh bao trung cut", "18.000"),
        ("Nuoc suoi Lavie 500ml", "7.000")
    ],
    subtotal=None,
    tax_name=None,
    tax_val=None,
    total_str="45.000 VND",
    cash_str="50.000 VND",
    change_str="5.000 VND"
)

