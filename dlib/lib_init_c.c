extern void attach(void);
extern void detach(void);

void __attach(void) __attribute__((constructor));
void __detach(void) __attribute__((destructor));

void __attach(void) { attach(); }
void __detach(void) { detach(); }

