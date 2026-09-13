import os
import re

def resolve_file(filepath, strategy):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # strategy: 'ours' (HEAD) or 'theirs' (incoming branch) or 'both'
    
    pattern = re.compile(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> [^\n]+', re.DOTALL)
    
    def repl(m):
        head = m.group(1)
        theirs = m.group(2)
        if strategy == 'ours': return head
        if strategy == 'theirs': return theirs
        # dashboard_screen needs ours (which has PendingApprovalCard)
        # payouts_screen needs theirs (which has FirebaseAuth)
        # colors.dart needs both if they are just additions
        return theirs

    if "colors.dart" in filepath:
        # Just manually check it
        pass
    
    new_content = pattern.sub(repl, content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

resolve_file('lib/common/constants/colors.dart', 'theirs') 
resolve_file('lib/owner_booking/presentation/screens/dashboard/dashboard_screen.dart', 'ours')
resolve_file('lib/owner_booking/presentation/screens/payouts/payouts_screen.dart', 'theirs')
print("Resolved conflicts")
