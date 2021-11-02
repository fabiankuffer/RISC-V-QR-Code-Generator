#   ___    ____             ____    ___    ____    _____            ____   _____   _   _   _____   ____       _      _____    ___    ____  
#  / _ \  |  _ \           / ___|  / _ \  |  _ \  | ____|          / ___| | ____| | \ | | | ____| |  _ \     / \    |_   _|  / _ \  |  _ \ 
# | | | | | |_) |  _____  | |     | | | | | | | | |  _|    _____  | |  _  |  _|   |  \| | |  _|   | |_) |   / _ \     | |   | | | | | |_) |
# | |_| | |  _ <  |_____| | |___  | |_| | | |_| | | |___  |_____| | |_| | | |___  | |\  | | |___  |  _ <   / ___ \    | |   | |_| | |  _ < 
#  \__\_\ |_| \_\          \____|  \___/  |____/  |_____|          \____| |_____| |_| \_| |_____| |_| \_\ /_/   \_\   |_|    \___/  |_| \_\
                                                                                                                                          
                                                                                                                                          
#data header that stores all
.include "qr_data.asm"

.text
#get the user input (message and error correction level)
jal ra, UI

#generate the error correction codes and bring data into the correct format
jal ra, p2_start

#find out the best masking pattern and display the final qr code
jal ra, draw

#quit the program
li a7, 10
ecall	

#functions for each part
.include "qr_generate-error-correction.asm"
.include "qr_draw.asm"
.include "qr_user-input.asm"