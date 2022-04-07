# Meta
## Documentation on the documentation

---

### Create table of contents

Create table of contents for markdown files:

     pandoc -f markdown -t markdown --toc -s --toc-depth=4 <INPUT_FILE> | less

Copy the toc from the pager output and then quit the pager and paste the result into the markdown document.

[Reference](https://stackoverflow.com/a/70102538/3697870)


### Edit Asciicasts

No official way. [asciinema-edit](https://github.com/cirocosta/asciinema-edit) doesn't work for cuts. This works for fixed formula edits:

    cat file.cast | { read; echo "$REPLY"; jq -c '.[0]=.[0]/4'; } > fast.cast

and the result can then be trimmed in a text editor.

Can also play back and [re-record](https://stackoverflow.com/a/57636493/3697870).
