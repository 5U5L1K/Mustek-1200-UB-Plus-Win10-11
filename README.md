# Mustek 1200 UB Plus Win10

Mustek Studio — приложение для **Mustek ScanExpress 1200 UB Plus** под
**Windows 10 x64**. USB ID сканера — **05D8:4002**. Для подключения
используются WinUSB и SANE GT68xx.

[Установщик MustekStudio-Setup.exe](MustekStudio-Setup.exe) ·
[SHA256](Setup-SHA256.txt) · [English instructions](#english)

## Установка

1. Откройте файл установщика в GitHub и нажмите **Download raw file**.
2. Запустите Setup, выберите язык и папку установки. В конце оставьте
   включённым «Завершить настройку сканера и открыть Mustek Studio».
3. Подключите сканер. Если открылся помощник, нажмите «Настроить WinUSB»
   и подтвердите запрос Windows. В Zadig выберите устройство с USB ID
   **05D8:4002** и драйвер **WinUSB**. Нажмите **Install Driver** или
   **Replace Driver**. Если устройство скрыто, откройте **Options → List All Devices**.
4. Откройте Mustek Studio. При первом запуске выберите папку для PDF и PNG.
   Изменить её можно в настройках. При отмене используется `MustekStudio.Data\scans`.

Zadig входит в установщик. Права администратора нужны для привязки WinUSB.
Рабочие страницы и настройки находятся в `MustekStudio.Data` рядом с приложением.

Для предпросмотра и сканирования можно выбрать разное разрешение. Добавляйте
страницы по одной и сохраняйте их в общий PDF или в отдельные PNG. Кнопка
«Убрать всё» очищает список страниц после подтверждения и сохраняет файлы
изображений. В настройках доступны русский и английский языки и две темы.

## Сборка

Потребуются Windows x64, Windows PowerShell 5.1, Python 3.10+ в `PATH`
и Inno Setup 7. Компилятор C# используется из .NET Framework.

Установите приложенный Setup. Скрипт восстановления берёт зависимости из
установленного приложения. Для другой папки установки передайте параметр
`-InstalledExe` с полным путём к `MustekStudio.exe`.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\Restore-Dependencies.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\Build-Setup.ps1 -InnoCompiler 'C:\Program Files\Inno Setup 7\ISCC.exe'
```

Укажите фактический путь к `ISCC.exe`. Сборка обновит установщик и файл SHA256
в корне. Исходники приложения и Setup находятся в `src`.

Лицензии и происхождение зависимостей описаны в [THIRD-PARTY.md](THIRD-PARTY.md).

## English

Mustek Studio is a scanner application for the **Mustek ScanExpress 1200 UB Plus**
on **Windows 10 x64**. It uses WinUSB and SANE GT68xx with USB ID **05D8:4002**.

[MustekStudio-Setup.exe](MustekStudio-Setup.exe) · [SHA256](Setup-SHA256.txt)

1. Open the installer file on GitHub and click **Download raw file**.
2. Run Setup, choose your language and an installation folder, then keep
   **Complete scanner setup and open Mustek Studio** selected.
3. Connect the scanner. If the assistant opens, click **Configure WinUSB**
   and approve the Windows prompt. In Zadig, select USB ID **05D8:4002** and
   **WinUSB**, then click **Install Driver** or **Replace Driver**. If needed,
   choose **Options → List All Devices**.
4. On first launch, choose the folder for PDF and PNG exports. You can change
   it in Settings. Canceling uses `MustekStudio.Data\scans`.

Zadig is bundled. Binding WinUSB requires administrator approval. The working
document and settings are stored in `MustekStudio.Data` beside the application.

You can choose preview and scan resolutions independently, save pages as PNG
or a single multipage PDF, and clear the page list with **Remove all** after
confirmation. The image files are kept. English and Russian and light and dark
themes are available in Settings.

### Build

Use Windows x64, Windows PowerShell 5.1, Python 3.10+ on `PATH`, and Inno Setup 7.
Install the provided setup, then run the two PowerShell commands under
[Сборка](#сборка). Pass `-InstalledExe` to the restore script if the app was
installed in a custom folder, and supply your actual `ISCC.exe` path. The build
updates the root installer and SHA256 file. Application and installer sources
are under `src`.

Dependency notices are in [THIRD-PARTY.md](THIRD-PARTY.md).
