# Meta
## Documentation on the documentation

---

### Create table of contents

Create table of contents for markdown files:

     pandoc -f markdown -t markdown --toc -s --toc-depth=4 <INPUT_FILE> | less

Copy the toc from the pager output and then quit the pager and paste the result into the markdown document.

[Reference](https://stackoverflow.com/a/70102538/3697870)
