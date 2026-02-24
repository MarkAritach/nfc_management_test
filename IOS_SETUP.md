# iOS NFC Setup Guide

## ข้อกำหนดเบื้องต้น

### 1. อุปกรณ์ที่รองรับ
- iPhone 7 หรือใหม่กว่า
- iOS 13.0 หรือใหม่กว่า
- NFC ต้องถูกเปิดใช้งาน (เปิดโดยอัตโนมัติใน iOS)

### 2. Apple Developer Account
- ต้องมี **Paid Apple Developer Account** ($99/year)
- **ไม่สามารถทดสอบ NFC ด้วย Free Account ได้**

---

## ขั้นตอนการตั้งค่า

### Step 1: เปิดโปรเจกต์ใน Xcode

```bash
cd ios
open Runner.xcworkspace
```

### Step 2: เพิ่ม NFC Capability

1. เลือก Project Navigator → Runner (ไอคอนสีฟ้า)
2. เลือก Target "Runner"
3. ไปที่แท็บ **"Signing & Capabilities"**
4. คลิก **"+ Capability"** ด้านบน
5. เลือก **"Near Field Communication Tag Reading"**

### Step 3: ตั้งค่า Bundle Identifier

1. ในแท็บ **"Signing & Capabilities"**
2. เปลี่ยน **Bundle Identifier** เป็นของคุณเอง (เช่น `com.yourcompany.nfcmanagement`)
3. เลือก **Team** ของคุณ (Apple Developer Account)

### Step 4: เพิ่ม Entitlements (ทำไว้ให้แล้ว)

ไฟล์ `Runner.entitlements` ถูกสร้างไว้แล้วที่:
- `ios/Runner/Runner.entitlements`

มี permissions:
- `com.apple.developer.nfc.readersession.formats`: NDEF และ TAG

### Step 5: ตรวจสอบ Info.plist (ทำไว้ให้แล้ว)

ไฟล์ `ios/Runner/Info.plist` มีการตั้งค่า:

```xml
<!-- NFC Permission Description -->
<key>NFCReaderUsageDescription</key>
<string>We need access to NFC to read and write tag data</string>

<!-- ISO7816 Select Identifiers for NDEF -->
<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>D2760000850101</string>
</array>
```

---

## การ Build และ Test

### 1. Build บน Device จริงเท่านั้น

**⚠️ NFC ไม่ทำงานบน Simulator**

```bash
flutter run -d <your-iphone-device-id>
```

### 2. ตรวจสอบ Device

```bash
flutter devices
```

### 3. วิธีใช้งาน NFC บน iOS

1. เปิดแอพ
2. กดปุ่ม "Start Scan"
3. **นำ NFC Tag ไปแตะที่ด้านบนของ iPhone**
   - iPhone จะสั่นเมื่อตรวจพบ Tag
   - แสดง Modal ข้อมูล Tag

---

## Common Issues

### ❌ "NFC is not available"

**สาเหตุ:**
- ทดสอบบน Simulator (NFC ต้องใช้ Device จริง)
- อุปกรณ์ไม่รองรับ NFC (iPhone 6s หรือเก่ากว่า)

**แก้ไข:**
- ใช้ iPhone 7 หรือใหม่กว่า
- Build บน Device จริง

---

### ❌ "Provisioning profile doesn't include NFC capability"

**สาเหตุ:**
- ใช้ Free Apple Developer Account
- Bundle Identifier ไม่ตรงกับ Provisioning Profile

**แก้ไข:**
1. ใช้ Paid Apple Developer Account
2. สร้าง App ID ใหม่ใน [Apple Developer Portal](https://developer.apple.com/account)
3. เปิด **NFC Tag Reading** capability
4. สร้าง Provisioning Profile ใหม่
5. Download และ Install Profile ใน Xcode

---

### ❌ "This app requires specific entitlements"

**สาเหตุ:**
- Entitlements ไม่ถูกต้อง
- App ID ไม่มี NFC capability

**แก้ไข:**
1. ไปที่ [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list)
2. เลือก App ID ของคุณ
3. เปิด **NFC Tag Reading**
4. Save
5. Re-download Provisioning Profile
6. Clean Build Folder ใน Xcode (Cmd + Shift + K)
7. Build ใหม่

---

## ข้อจำกัดของ iOS

### 1. Background NFC
- iOS **ไม่รองรับ** Background NFC
- แอพต้องเปิดอยู่และ Active

### 2. Foreground Session
- ต้อง Start Session ก่อนสแกน
- Session หมดเวลา (timeout) หลัง 60 วินาที
- ต้อง Start Session ใหม่ทุกครั้งหลังสแกนเสร็จ

### 3. Write Permissions
- iOS รองรับการเขียน NDEF Tags
- บาง Tag types อาจไม่รองรับ
- ต้องเป็น Tag ที่ Writable

### 4. Tag Types
iOS รองรับ:
- ✅ NDEF (NFC Data Exchange Format)
- ✅ ISO 7816
- ✅ ISO 15693
- ✅ FeliCa
- ✅ MIFARE

---

## Testing Checklist

- [ ] ใช้ Paid Apple Developer Account
- [ ] Build บน Device จริง (iPhone 7+)
- [ ] เปิด NFC Capability ใน Xcode
- [ ] Bundle Identifier ตรงกับ Provisioning Profile
- [ ] ลอง Start Scan แล้วแตะ NFC Tag
- [ ] ตรวจสอบ Permission Popup
- [ ] ทดสอบ Write และ Clear Tag

---

## Resources

- [Apple NFC Documentation](https://developer.apple.com/documentation/corenfc)
- [nfc_manager Plugin](https://pub.dev/packages/nfc_manager)
- [iOS NFC Limitations](https://developer.apple.com/documentation/corenfc/adding_support_for_background_tag_reading)

---

## Contact

หากมีปัญหาเพิ่มเติม กรุณาติดต่อทีมพัฒนา
