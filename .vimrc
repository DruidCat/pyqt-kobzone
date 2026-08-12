"Сохранить все открытые изменённые файл и Запустить проект с помощью клавиши Alt+F7

" Запуск скрипта через Alt+F7

"nnoremap <a-F7> :wa<cr>:!cd ~/git/kobzone && source venv/bin/activate && python transcribe.py<cr>
"inoremap <a-F7> <ESC>:wa<cr>:!cd ~/git/kobzone && source venv/bin/activate && python transcribe.py<cr>
"
"
"
if has('win32')
	nnoremap <a-F7> :wa<cr>:!cd ~/git/pyqt-kobzone && source venv/Scripts/activate && python main.py<cr>
	inoremap <a-F7> <ESC>:wa<cr>:!cd ~/git/pyqt-kobzone && source venv/Scripts/activate && python main.py<cr>
endif
if has('unix')
	nnoremap <a-F7> :wa<cr>:!cd ~/git/kobzone && source venv/bin/activate && python main.py<cr>
	inoremap <a-F7> <ESC>:wa<cr>:!cd ~/git/kobzone && source venv/bin/activate && python main.py<cr>
endif
