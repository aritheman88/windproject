import os, fitz, shutil, docx


os.chdir(r'C:\Users\ariel\OneDrive\Desktop\Python\wind')
project_list = [
    'כסרא',
    'חפציבה',
    'לביא',
    'דגניה',
    'רמת סירין',
    'מעלה גלבוע',
    'מירב',
    'כוכב הירדן',
    'אשדות יעקב',
    'מסילות',
    'דלתון'
    ]

# project_list = [
#     '0367599',
#     '0378315',
#     '0455436',
#     '0390385',
#     '0415083',
#     '0390393',
#     '0458604',
#     '0310045',
#     '0310029',
#     '0322776',
#     '0322529',
#     '0322529',
#     '0322560',
#     '0322552',
#     '0322750',
#     '0310136',
#     '0305128'
#     ]
for project in project_list:
    print("Now working on ", project)
    path = r'C:\Users\ariel\OneDrive\Desktop\Python\wind'
    path = str(path) + "\\" + project
    # os.mkdir(path)
    os.chdir(r'C:\Users\ariel\OneDrive\Desktop\Python\wind')
    this_count = 0
    for file in os.listdir():

        ### PDF files
        # if file.endswith(".pdf"):
        #     this_project = False
        #     with open(file, 'rb') as pdf_file:
        #         # Create a PyMuPDF Document object
        #         pdf_document = fitz.open(stream=pdf_file.read(), filetype='pdf')
        #         page_number = 1
        #         # Loop through each page in the PDF file
        #         for page_num in range(pdf_document.page_count):
        #             ### was:     for page_num in range(pdf_document.page_count):
        #             # Get the page object
        #             try:
        #                 page = pdf_document[page_num]
        #                 # print("Page number: ", page_number)
        #                 page_number += 1
        #                 # Extract the text from the page
        #                 text = page.get_text()
        #                 lines = text.split("\n")
        #                 reversed_lines = []
        #                 for line in lines:
        #                     reversed_line = line[::-1]
        #                     reversed_lines.append(reversed_line)
        #                 reversed_text = "\n".join(reversed_lines)
        #                 if project in reversed_text and 'טורבינות' in reversed_text:
        #                     this_project = True
        #             except:
        #                 print('')
        #     #### Move file to the subfolder
        #     if this_project:
        #         this_count += 1
        #         shutil.copy(file, path)
        ### DOCX files
        if file.endswith(".docx"):
            this_project = False
            try:
                # Open the docx file
                doc = docx.Document(file)
                # Loop through each paragraph in the document
                for para in doc.paragraphs:
                    # Extract the text from the paragraph
                    text = para.text
                    # Check if the project and 'טורבינות' are in the text
                    if project in text and 'טורבינות' in text:
                        this_project = True
                        break
            except:
                print('')
            #### Move file to the subfolder
            if this_project:
                this_count += 1
                shutil.copy(file, path)
    print("Total files found for this project: ", this_count)

