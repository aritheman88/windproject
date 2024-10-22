import os, PyPDF2, fitz, shutil

os.chdir(r'C:\Users\ariel\OneDrive\Desktop\Python\wind')
count_turbines = 0
no_turbines = 0
for file in os.listdir():
    if file.endswith(".pdf"):
        turbines_exist = False
        interesting_file = False

        ##### Process with PyMuPDF:
        with open(file, 'rb') as pdf_file:
            # Create a PyMuPDF Document object
            pdf_document = fitz.open(stream=pdf_file.read(), filetype='pdf')
            page_number = 1
            # Loop through each page in the PDF file
            for page_num in range(pdf_document.page_count):
                ### was:     for page_num in range(pdf_document.page_count):
                # Get the page object
                try:
                    page = pdf_document[page_num]
                    # print("Page number: ", page_number)
                    page_number += 1
                    # Extract the text from the page
                    text = page.get_text()
                    lines = text.split("\n")
                    reversed_lines = []
                    for line in lines:
                        reversed_line = line[::-1]
                        reversed_lines.append(reversed_line)
                    reversed_text = "\n".join(reversed_lines)
                    if 'טורבינות' in reversed_text:
                        turbines_exist = True
                        count = reversed_text.count('טורבינות')
                        if count > 1:
                            print("File ", file , " looks interesting.")
                            interesting_file = True
                        # print("Turbines were found in file ", file, " on page ", page_number)
                    # if 'קצרות' in reversed_text:
                    #     print("Found קצרות in page ", page_number)
                    # print(reversed_text)
                except:
                    print('')
        #### Move file to the subfolder
        # new_folder_path = r'C:\Users\ariel\OneDrive\Desktop\Python\wind\wind_sessions'
        # if turbines_exist:
        #     shutil.copy(file, new_folder_path)
        new_folder_path2 = r'C:\Users\ariel\OneDrive\Desktop\Python\wind\more_than_one'
        if interesting_file:
            shutil.copy(file, new_folder_path2)

