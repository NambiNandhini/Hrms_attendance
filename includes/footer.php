</main>
</div>
</div>
<script>
    document.querySelectorAll('[data-modal]').forEach(b => b.addEventListener('click', () => document.getElementById(b.dataset.modal).classList.add('show')));
    document.querySelectorAll('.modal .close').forEach(b => b.addEventListener('click', () => b.closest('.modal').classList.remove('show')));
    document.querySelectorAll('.modal').forEach(m => m.addEventListener('click', e => {
        if (e.target === m) m.classList.remove('show')
    }));
    const pdfDownload = document.querySelector('a[href^="download.php?month="]');
    if (pdfDownload) {
        document.querySelectorAll('a[href^="excel.php"]').forEach(link => link.remove());
        const excelDownload = document.createElement('a');
        excelDownload.className = pdfDownload.className;
        excelDownload.textContent = 'Download Excel';
        excelDownload.href = 'excel.php' + new URL(pdfDownload.href).search;
        pdfDownload.insertAdjacentElement('afterend', excelDownload);
        const monthPicker = document.querySelector('.month-picker');
        const employeeNotice = document.querySelector('.notice');
        if (monthPicker && employeeNotice) {
            monthPicker.className = 'filters';
            employeeNotice.insertAdjacentElement('afterend', monthPicker);
        }
    }
</script>
</body>

</html>