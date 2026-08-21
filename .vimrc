"Сохранить все открытые изменённые файл и Запустить проект с помощью клавиши Alt+F7
if has('win32')
    nnoremap <a-F7> :wa<cr>:!cd ~/git/pyqt-kobzone && source venv/Scripts/activate && python DCScripts/DCCompileRCC.py && python main.py<cr>
"    nnoremap <a-F7> :wa<cr>:!cd ~/git/pyqt-kobzone && source venv/Scripts/activate && python compile_rcc.py && python main.py<cr>
    inoremap <a-F7> <ESC>:wa<cr>:!cd ~/git/pyqt-kobzone && source venv/Scripts/activate && python DCScripts/DCCompileRCC.py && python main.py<cr>
"    inoremap <a-F7> <ESC>:wa<cr>:!cd ~/git/pyqt-kobzone && source venv/Scripts/activate && python compile_rcc.py && python main.py<cr>
endif
if has('unix')
    nnoremap <a-F7> :wa<cr>:!cd ~/git/kobzone && source venv/bin/activate && python DCScripts/DCCompileRCC.py && python main.py<cr>
"    nnoremap <a-F7> :wa<cr>:!cd ~/git/kobzone && source venv/bin/activate && python compile_rcc.py && python main.py<cr>
    inoremap <a-F7> <ESC>:wa<cr>:!cd ~/git/kobzone && source venv/bin/activate && python DCScripts/DCCompileRCC.py && python main.py<cr>
"    inoremap <a-F7> <ESC>:wa<cr>:!cd ~/git/kobzone && source venv/bin/activate && python compile_rcc.py && python main.py<cr>
endif
