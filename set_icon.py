#!/usr/bin/env python
"""
Замени иконку приложения shzq.
Запусти: python set_icon.py <путь_к_картинке>
Например: python set_icon.py ~/Downloads/icon.png

Картинка будет скопирована как layout/Resources/icon.png
"""
import sys, shutil, os

if len(sys.argv) < 2:
    print("Использование: python set_icon.py <путь_к_картинке>")
    sys.exit(1)

src = sys.argv[1]
if not os.path.exists(src):
    print(f"Файл не найден: {src}")
    sys.exit(1)

dst = os.path.join(os.path.dirname(__file__), "layout", "Resources", "icon.png")
shutil.copy2(src, dst)
print(f"Иконка заменена: {dst}")
