<!-- SMN Dashboard -->
<!DOCTYPE html>
<html class="light" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>SMN Dashboard</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#0da2e7",
                        "background-light": "#f5f7f8",
                        "background-dark": "#101c22",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: {
                        "DEFAULT": "0.25rem",
                        "lg": "0.5rem",
                        "xl": "0.75rem",
                        "2xl": "1rem",
                        "full": "9999px"
                    },
                    boxShadow: {
                        'soft': '0 2px 10px rgba(0, 0, 0, 0.03)',
                        'card': '0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03)',
                    }
                },
            },
        }
    </script>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark font-display antialiased min-h-screen pb-24">
<div class="w-full h-12 bg-transparent"></div>
<header class="px-5 pb-2">
<div class="flex items-center justify-between mb-6">
<div>
<h1 class="text-2xl font-bold text-gray-900 dark:text-white tracking-tight">SMN Dashboard</h1>
<p class="text-sm text-gray-500 dark:text-gray-400">Manage your structured data</p>
</div>
<div class="relative">
<button class="w-10 h-10 rounded-full overflow-hidden border-2 border-white dark:border-gray-700 shadow-sm">
<img alt="User Profile" class="w-full h-full object-cover" data-alt="User profile avatar placeholder" src="https://lh3.googleusercontent.com/aida-public/AB6AXuAmuxJPUPYM6srE40D2Q7rsLa3FCIXs3tC7XaQDQQl-3d5hk_iWNrwT6eM7PPqoFOS0yDR4xY61AC7mrwOcmJnYS8t1kb-Vf6OHjWhchKa-53MlkIJRYHE1GNgpk9KHXYTlP-7sVRgoGPtI3388Xvjr13yD5sbW6vubimuo18UEWFzpq6DJ6PyULru9VnNTxtQv54-Axa_BE5-jY79AyWl4DE2KvD-ridudEvjs8S2scMQWhLTrMMLooZghizxZbTr_jFbEs80tLmk"/>
</button>
<div class="absolute bottom-0 right-0 w-3 h-3 bg-green-500 rounded-full border-2 border-background-light dark:border-background-dark"></div>
</div>
</div>
<div class="flex items-center gap-2 mb-4 bg-white dark:bg-gray-800 rounded-lg p-3 shadow-soft border border-gray-100 dark:border-gray-700">
<span class="material-symbols-outlined text-green-500 text-[20px]">check_circle</span>
<span class="text-sm font-medium text-gray-700 dark:text-gray-200">System Healthy: All notes compliant</span>
</div>
<div class="relative group">
<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
<span class="material-symbols-outlined text-gray-400 group-focus-within:text-primary transition-colors">search</span>
</div>
<input class="block w-full pl-10 pr-3 py-3 border-none rounded-xl leading-5 bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary/50 shadow-soft transition-all" placeholder="Search notes, tags, or content..." type="text"/>
<div class="absolute inset-y-0 right-0 pr-2 flex items-center">
<button class="p-1 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-400 transition-colors">
<span class="material-symbols-outlined text-[20px]">tune</span>
</button>
</div>
</div>
</header>
<section class="mt-4 px-5">
<div class="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-hide">
<button class="px-4 py-1.5 rounded-full bg-primary text-white text-xs font-semibold shadow-sm flex-shrink-0">All Notes</button>
<button class="px-4 py-1.5 rounded-full bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 border border-gray-200 dark:border-gray-700 text-xs font-medium hover:border-primary/50 transition-colors flex-shrink-0">Personal</button>
<button class="px-4 py-1.5 rounded-full bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 border border-gray-200 dark:border-gray-700 text-xs font-medium hover:border-primary/50 transition-colors flex-shrink-0">Work</button>
<button class="px-4 py-1.5 rounded-full bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 border border-gray-200 dark:border-gray-700 text-xs font-medium hover:border-primary/50 transition-colors flex-shrink-0">Travel</button>
<button class="px-4 py-1.5 rounded-full bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 border border-gray-200 dark:border-gray-700 text-xs font-medium hover:border-primary/50 transition-colors flex-shrink-0">Family</button>
</div>
</section>
<section class="mt-2 px-5 pb-24">
<div class="flex items-center justify-between mb-4">
<h2 class="text-lg font-bold text-gray-900 dark:text-white">Recent Notes</h2>
<button class="p-1 text-gray-400 hover:text-primary">
<span class="material-symbols-outlined text-[20px]">sort</span>
</button>
</div>
<div class="flex flex-col gap-3">
<div class="group flex items-center p-4 bg-white dark:bg-gray-800 rounded-xl shadow-soft border border-gray-100 dark:border-gray-700 hover:shadow-md transition-all cursor-pointer">
<div class="h-12 w-12 rounded-lg bg-indigo-50 dark:bg-indigo-900/20 flex items-center justify-center flex-shrink-0 text-indigo-500">
<span class="material-symbols-outlined">lock</span>
</div>
<div class="ml-4 flex-1 min-w-0">
<div class="flex items-center justify-between">
<h3 class="text-sm font-bold text-gray-900 dark:text-white truncate">Main_Vault_Backup.md</h3>
<span class="text-[10px] text-gray-400">2h ago</span>
</div>
<div class="flex items-center mt-1 gap-2">
<span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-medium bg-indigo-100 text-indigo-800 dark:bg-indigo-900/50 dark:text-indigo-300">
                            PERSONAL
                        </span>
<span class="text-xs text-gray-500 dark:text-gray-400 truncate">Encrypted keys for cold storage</span>
</div>
</div>
<span class="material-symbols-outlined text-gray-300 group-hover:text-primary ml-2">chevron_right</span>
</div>
<div class="group flex items-center p-4 bg-white dark:bg-gray-800 rounded-xl shadow-soft border border-gray-100 dark:border-gray-700 hover:shadow-md transition-all cursor-pointer">
<div class="h-12 w-12 rounded-lg bg-sky-50 dark:bg-sky-900/20 flex items-center justify-center flex-shrink-0 text-sky-500">
<span class="material-symbols-outlined">flight</span>
</div>
<div class="ml-4 flex-1 min-w-0">
<div class="flex items-center justify-between">
<h3 class="text-sm font-bold text-gray-900 dark:text-white truncate">Japan_Itinerary_2024.md</h3>
<span class="text-[10px] text-gray-400">Yesterday</span>
</div>
<div class="flex items-center mt-1 gap-2">
<span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-medium bg-sky-100 text-sky-800 dark:bg-sky-900/50 dark:text-sky-300">
                            TRAVEL
                        </span>
<span class="text-xs text-gray-500 dark:text-gray-400 truncate">Hotel reservations and train pass</span>
</div>
</div>
<span class="material-symbols-outlined text-gray-300 group-hover:text-primary ml-2">chevron_right</span>
</div>
<div class="group flex items-center p-4 bg-white dark:bg-gray-800 rounded-xl shadow-soft border border-gray-100 dark:border-gray-700 hover:shadow-md transition-all cursor-pointer">
<div class="h-12 w-12 rounded-lg bg-rose-50 dark:bg-rose-900/20 flex items-center justify-center flex-shrink-0 text-rose-500">
<span class="material-symbols-outlined">health_and_safety</span>
</div>
<div class="ml-4 flex-1 min-w-0">
<div class="flex items-center justify-between">
<h3 class="text-sm font-bold text-gray-900 dark:text-white truncate">Health_Records_Kids.md</h3>
<span class="text-[10px] text-gray-400">3d ago</span>
</div>
<div class="flex items-center mt-1 gap-2">
<span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-medium bg-rose-100 text-rose-800 dark:bg-rose-900/50 dark:text-rose-300">
                            FAMILY
                        </span>
<span class="text-xs text-gray-500 dark:text-gray-400 truncate">Vaccination dates updated</span>
</div>
</div>
<span class="material-symbols-outlined text-gray-300 group-hover:text-primary ml-2">chevron_right</span>
</div>
<div class="group flex items-center p-4 bg-white dark:bg-gray-800 rounded-xl shadow-soft border border-gray-100 dark:border-gray-700 hover:shadow-md transition-all cursor-pointer">
<div class="h-12 w-12 rounded-lg bg-gray-50 dark:bg-gray-700 flex items-center justify-center flex-shrink-0 text-gray-500 dark:text-gray-300">
<span class="material-symbols-outlined">description</span>
</div>
<div class="ml-4 flex-1 min-w-0">
<div class="flex items-center justify-between">
<h3 class="text-sm font-bold text-gray-900 dark:text-white truncate">Project_Zephyr_Specs.md</h3>
<span class="text-[10px] text-gray-400">1w ago</span>
</div>
<div class="flex items-center mt-1 gap-2">
<span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300">
                            WORK
                        </span>
<span class="text-xs text-gray-500 dark:text-gray-400 truncate">Q3 technical requirements</span>
</div>
</div>
<span class="material-symbols-outlined text-gray-300 group-hover:text-primary ml-2">chevron_right</span>
</div>
<div class="group flex items-center p-4 bg-white dark:bg-gray-800 rounded-xl shadow-soft border border-gray-100 dark:border-gray-700 hover:shadow-md transition-all cursor-pointer">
<div class="h-12 w-12 rounded-lg bg-emerald-50 dark:bg-emerald-900/20 flex items-center justify-center flex-shrink-0 text-emerald-500">
<span class="material-symbols-outlined">receipt_long</span>
</div>
<div class="ml-4 flex-1 min-w-0">
<div class="flex items-center justify-between">
<h3 class="text-sm font-bold text-gray-900 dark:text-white truncate">Q4_Expenses_Draft.md</h3>
<span class="text-[10px] text-gray-400">2w ago</span>
</div>
<div class="flex items-center mt-1 gap-2">
<span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-medium bg-emerald-100 text-emerald-800 dark:bg-emerald-900/50 dark:text-emerald-300">
                            FINANCE
                        </span>
<span class="text-xs text-gray-500 dark:text-gray-400 truncate">Pending review by accounting</span>
</div>
</div>
<span class="material-symbols-outlined text-gray-300 group-hover:text-primary ml-2">chevron_right</span>
</div>
</div>
</section>
<div class="fixed bottom-24 right-5 z-20">
<button class="flex items-center justify-center w-14 h-14 bg-primary text-white rounded-full shadow-lg shadow-primary/40 hover:bg-primary/90 transition-all hover:scale-105 active:scale-95">
<span class="material-symbols-outlined text-[28px]">add</span>
</button>
</div>
<nav class="fixed bottom-0 left-0 right-0 bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700 pb-5 pt-3 px-2 flex justify-around items-center z-10">
<button class="flex flex-col items-center gap-1 w-16 text-primary">
<span class="material-symbols-outlined fill-current">grid_view</span>
<span class="text-[10px] font-medium">Home</span>
</button>
<button class="flex flex-col items-center gap-1 w-16 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
<span class="material-symbols-outlined">folder_open</span>
<span class="text-[10px] font-medium">Files</span>
</button>
<button class="flex flex-col items-center gap-1 w-16 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
<span class="material-symbols-outlined">extension</span>
<span class="text-[10px] font-medium">Templates</span>
</button>
<button class="flex flex-col items-center gap-1 w-16 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
<span class="material-symbols-outlined">settings</span>
<span class="text-[10px] font-medium">Settings</span>
</button>
</nav>

</body></html>

<!-- Edit Note: Family Login -->
<!DOCTYPE html>
<html class="light" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Edit Note: Family Login</title>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#0da2e7",
                        "background-light": "#f5f7f8",
                        "background-dark": "#101c22",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: {"DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "full": "9999px"},
                },
            },
        }
    </script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<style>::-webkit-scrollbar {
            width: 6px;
        }
        ::-webkit-scrollbar-track {
            background: transparent;
        }
        ::-webkit-scrollbar-thumb {
            background: #cbd5e1;
            border-radius: 3px;
        }
        .dark ::-webkit-scrollbar-thumb {
            background: #334155;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark text-[#111618] dark:text-gray-100 font-display min-h-screen flex flex-col overflow-x-hidden transition-colors duration-200">
<header class="sticky top-0 z-30 flex items-center bg-background-light/95 dark:bg-background-dark/95 backdrop-blur-sm p-4 pb-2 justify-between border-b border-gray-200 dark:border-gray-800 transition-colors">
<button class="flex size-10 shrink-0 items-center justify-center rounded-full hover:bg-gray-200 dark:hover:bg-gray-800 transition-colors text-[#111618] dark:text-white">
<span class="material-symbols-outlined">arrow_back_ios_new</span>
</button>
<h2 class="text-[#111618] dark:text-white text-lg font-bold leading-tight tracking-[-0.015em] flex-1 text-center">Edit Note</h2>
<div class="flex w-10 items-center justify-end">
<button class="flex size-10 shrink-0 items-center justify-center rounded-full hover:bg-gray-200 dark:hover:bg-gray-800 transition-colors text-[#111618] dark:text-white">
<span class="material-symbols-outlined">more_horiz</span>
</button>
</div>
</header>
<main class="flex-1 flex flex-col p-4 gap-6 pb-24">
<section class="flex flex-col gap-4">
<div class="flex flex-col gap-1">
<label class="sr-only" for="note-title">Note Title</label>
<input class="w-full bg-transparent text-3xl font-bold text-[#111618] dark:text-white placeholder-gray-400 focus:outline-none border-none p-0 focus:ring-0" id="note-title" placeholder="Untitled Note" type="text" value="Family Login"/>
</div>
<div class="flex items-center gap-2">
<button class="flex h-8 shrink-0 items-center justify-center gap-x-2 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 pl-2 pr-3 shadow-sm hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
<span class="material-symbols-outlined text-primary text-[18px]">folder_open</span>
<span class="text-[#111618] dark:text-gray-200 text-sm font-medium leading-normal">Category: Passwords</span>
<span class="material-symbols-outlined text-gray-400 text-[16px]">expand_more</span>
</button>
<button class="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 shadow-sm hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors text-gray-500 dark:text-gray-400">
<span class="material-symbols-outlined text-[18px]">star</span>
</button>
</div>
</section>
<section class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden">
<div class="p-5 flex flex-col gap-5 pt-6">
<div class="flex flex-col gap-2">
<label class="text-[#111618] dark:text-gray-300 text-sm font-medium leading-normal">Service Name</label>
<div class="relative group">
<div class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-primary transition-colors">
<span class="material-symbols-outlined">subscriptions</span>
</div>
<input class="form-input flex w-full rounded-lg text-[#111618] dark:text-white border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700/50 focus:bg-white dark:focus:bg-gray-700 focus:border-primary focus:ring-1 focus:ring-primary h-12 pl-10 pr-4 text-base transition-all" type="text" value="Netflix"/>
</div>
</div>
<div class="flex flex-col gap-2">
<label class="text-[#111618] dark:text-gray-300 text-sm font-medium leading-normal">Account Owner</label>
<div class="relative">
<div class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
<span class="material-symbols-outlined">person</span>
</div>
<select class="form-select w-full rounded-lg text-[#111618] dark:text-white border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700/50 focus:bg-white dark:focus:bg-gray-700 focus:border-primary focus:ring-1 focus:ring-primary h-12 pl-10 pr-10 text-base appearance-none transition-all">
<option selected="" value="dad">Dad</option>
<option value="mom">Mom</option>
<option value="kids">Kids</option>
</select>
<div class="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-gray-400">
<span class="material-symbols-outlined">expand_more</span>
</div>
</div>
</div>
<div class="flex flex-col gap-2">
<label class="text-[#111618] dark:text-gray-300 text-sm font-medium leading-normal">Password</label>
<div class="relative group">
<div class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-primary transition-colors">
<span class="material-symbols-outlined">lock</span>
</div>
<input class="form-input flex w-full rounded-lg text-[#111618] dark:text-white border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700/50 focus:bg-white dark:focus:bg-gray-700 focus:border-primary focus:ring-1 focus:ring-primary h-12 pl-10 pr-12 text-base transition-all" type="password" value="SuperSecret123"/>
<button class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 focus:outline-none">
<span class="material-symbols-outlined">visibility</span>
</button>
</div>
<div class="flex items-center gap-2 mt-1">
<div class="h-1 flex-1 bg-green-500 rounded-full"></div>
<div class="h-1 flex-1 bg-green-500 rounded-full"></div>
<div class="h-1 flex-1 bg-green-500 rounded-full"></div>
<div class="h-1 flex-1 bg-gray-200 dark:bg-gray-600 rounded-full"></div>
<span class="text-xs text-green-600 font-medium ml-1">Strong</span>
</div>
</div>
<div class="flex flex-col gap-2">
<div class="flex justify-between items-center">
<label class="text-[#111618] dark:text-gray-300 text-sm font-medium leading-normal">Created On</label>
<div class="bg-gray-100 dark:bg-gray-700 p-0.5 rounded-lg flex text-xs font-medium">
<button class="px-3 py-1 rounded-md bg-white dark:bg-gray-600 shadow-sm text-primary dark:text-white">Gregorian</button>
<button class="px-3 py-1 rounded-md text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200">Hijri</button>
</div>
</div>
<div class="relative group">
<div class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-primary transition-colors">
<span class="material-symbols-outlined">calendar_month</span>
</div>
<input class="form-input flex w-full rounded-lg text-[#111618] dark:text-white border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700/50 focus:bg-white dark:focus:bg-gray-700 focus:border-primary focus:ring-1 focus:ring-primary h-12 pl-10 pr-4 text-base transition-all" type="date" value="2023-10-25"/>
</div>
<p class="text-xs text-gray-500 dark:text-gray-400 mt-1 pl-1">Hijri equivalent: 10 Rabi' al-Thani 1445</p>
</div>
</div>
<div class="p-5 border-t border-gray-100 dark:border-gray-700 bg-gray-50/50 dark:bg-gray-800/50">
<button class="flex w-full items-center justify-center gap-2 rounded-lg border border-dashed border-primary/40 bg-primary/5 hover:bg-primary/10 dark:bg-primary/10 dark:hover:bg-primary/20 py-3 text-primary font-bold transition-all active:scale-[0.99]">
<span class="material-symbols-outlined text-[20px]">add_circle</span>
                    Add Another Record
                </button>
</div>
</section>
<p class="text-center text-xs text-gray-400 dark:text-gray-500 px-8">
            This note is encrypted end-to-end. Only you can view this data.
        </p>
</main>
<div class="fixed bottom-6 right-6 z-40">
<button class="flex size-14 items-center justify-center rounded-full bg-primary text-white shadow-lg shadow-primary/30 hover:shadow-primary/50 hover:bg-sky-500 transition-all active:scale-90">
<span class="material-symbols-outlined text-[28px]">save</span>
</button>
</div>
</body></html>

<!-- Note View: List Layout -->
<!DOCTYPE html>

<html class="light" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Server Credentials Note</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#0da2e7",
                        "background-light": "#f5f7f8",
                        "background-dark": "#101c22",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: {"DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "full": "9999px"},
                },
            },
        }
    </script>
<style>
        body {
            font-family: 'Inter', sans-serif;
        }
        .hide-scrollbar::-webkit-scrollbar {
            display: none;
        }
        .hide-scrollbar {
            -ms-overflow-style: none;
            scrollbar-width: none;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark text-slate-900 dark:text-white flex flex-col min-h-screen font-display overflow-x-hidden">
<!-- Header Section -->
<header class="sticky top-0 z-20 bg-white dark:bg-[#1a2c36] border-b border-slate-200 dark:border-slate-800">
<div class="px-4 py-3 flex items-center justify-between">
<button class="p-2 -ml-2 rounded-full hover:bg-slate-100 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300 transition-colors">
<span class="material-symbols-outlined">arrow_back</span>
</button>
<div class="flex-1 text-center">
<span class="text-xs font-medium text-slate-400 dark:text-slate-500 uppercase tracking-wider">Note View</span>
</div>
<button class="p-2 -mr-2 rounded-full hover:bg-slate-100 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300 transition-colors">
<span class="material-symbols-outlined">more_horiz</span>
</button>
</div>
<!-- Title & Metadata -->
<div class="px-5 pb-4 pt-1">
<div class="flex flex-col gap-2">
<h1 class="text-2xl font-bold text-slate-900 dark:text-white leading-tight">Server Credentials</h1>
<div class="flex items-center gap-3">
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-200">
                        Work
                    </span>
<span class="text-xs text-slate-400 flex items-center gap-1">
<span class="material-symbols-outlined text-[14px]">schedule</span>
                        Last edited 2h ago
                    </span>
</div>
</div>
</div>
</header>
<!-- Main Content Area: List/Table -->
<main class="flex-1 px-4 py-6 w-full max-w-2xl mx-auto space-y-4 pb-24">
<!-- Filter / Search Row -->
<div class="flex items-center gap-2 mb-2">
<div class="relative flex-1">
<span class="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-lg">search</span>
<input class="w-full bg-white dark:bg-[#1a2c36] border border-slate-200 dark:border-slate-700 rounded-lg py-2 pl-9 pr-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary/50 text-slate-700 dark:text-slate-200 placeholder:text-slate-400" placeholder="Search servers..." type="text"/>
</div>
<button class="p-2 bg-white dark:bg-[#1a2c36] border border-slate-200 dark:border-slate-700 rounded-lg text-slate-600 dark:text-slate-300">
<span class="material-symbols-outlined">filter_list</span>
</button>
</div>
<!-- Column Headers (Pseudo-Table) -->
<div class="hidden sm:flex px-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">
<div class="flex-1">Server Name</div>
<div class="w-32">IP Address</div>
<div class="w-24 text-right">Status</div>
</div>
<!-- List Item 1 -->
<div class="group relative bg-white dark:bg-[#1a2c36] rounded-xl p-4 shadow-sm border border-slate-100 dark:border-slate-800 active:scale-[0.99] transition-transform duration-100">
<div class="flex items-start justify-between gap-4">
<div class="flex items-start gap-3 flex-1">
<div class="h-10 w-10 rounded-lg bg-emerald-50 dark:bg-emerald-900/20 flex items-center justify-center shrink-0 text-emerald-600 dark:text-emerald-400">
<span class="material-symbols-outlined">dns</span>
</div>
<div class="flex flex-col">
<h3 class="font-semibold text-slate-900 dark:text-white text-base leading-snug">production-db-01</h3>
<span class="font-mono text-xs text-slate-500 dark:text-slate-400 mt-0.5">192.168.1.10</span>
<div class="flex sm:hidden mt-2 items-center gap-1.5">
<span class="relative flex h-2 w-2">
<span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
<span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
</span>
<span class="text-xs font-medium text-emerald-600 dark:text-emerald-400">Online</span>
</div>
</div>
</div>
<!-- Desktop Status View -->
<div class="hidden sm:flex flex-col items-end gap-1">
<span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300">
<span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                        Online
                    </span>
</div>
<button class="text-slate-300 dark:text-slate-600 hover:text-primary dark:hover:text-primary transition-colors">
<span class="material-symbols-outlined">chevron_right</span>
</button>
</div>
</div>
<!-- List Item 2 -->
<div class="group relative bg-white dark:bg-[#1a2c36] rounded-xl p-4 shadow-sm border border-slate-100 dark:border-slate-800 active:scale-[0.99] transition-transform duration-100">
<div class="flex items-start justify-between gap-4">
<div class="flex items-start gap-3 flex-1">
<div class="h-10 w-10 rounded-lg bg-orange-50 dark:bg-orange-900/20 flex items-center justify-center shrink-0 text-orange-500 dark:text-orange-400">
<span class="material-symbols-outlined">construction</span>
</div>
<div class="flex flex-col">
<h3 class="font-semibold text-slate-900 dark:text-white text-base leading-snug">staging-web-01</h3>
<span class="font-mono text-xs text-slate-500 dark:text-slate-400 mt-0.5">10.0.0.5</span>
<div class="flex sm:hidden mt-2 items-center gap-1.5">
<span class="relative inline-flex rounded-full h-2 w-2 bg-orange-500"></span>
<span class="text-xs font-medium text-orange-600 dark:text-orange-400">Maintenance</span>
</div>
</div>
</div>
<!-- Desktop Status View -->
<div class="hidden sm:flex flex-col items-end gap-1">
<span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-orange-50 text-orange-700 dark:bg-orange-900/30 dark:text-orange-300">
<span class="w-1.5 h-1.5 rounded-full bg-orange-500"></span>
                       Maintenance
                   </span>
</div>
<button class="text-slate-300 dark:text-slate-600 hover:text-primary dark:hover:text-primary transition-colors">
<span class="material-symbols-outlined">chevron_right</span>
</button>
</div>
</div>
<!-- List Item 3 -->
<div class="group relative bg-white dark:bg-[#1a2c36] rounded-xl p-4 shadow-sm border border-slate-100 dark:border-slate-800 active:scale-[0.99] transition-transform duration-100 opacity-75">
<div class="flex items-start justify-between gap-4">
<div class="flex items-start gap-3 flex-1">
<div class="h-10 w-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center shrink-0 text-slate-500 dark:text-slate-400">
<span class="material-symbols-outlined">cloud_off</span>
</div>
<div class="flex flex-col">
<h3 class="font-semibold text-slate-900 dark:text-white text-base leading-snug">dev-cache-02</h3>
<span class="font-mono text-xs text-slate-500 dark:text-slate-400 mt-0.5">127.0.0.1</span>
<div class="flex sm:hidden mt-2 items-center gap-1.5">
<span class="relative inline-flex rounded-full h-2 w-2 bg-slate-400"></span>
<span class="text-xs font-medium text-slate-500 dark:text-slate-400">Offline</span>
</div>
</div>
</div>
<!-- Desktop Status View -->
<div class="hidden sm:flex flex-col items-end gap-1">
<span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400">
<span class="w-1.5 h-1.5 rounded-full bg-slate-400"></span>
                       Offline
                   </span>
</div>
<button class="text-slate-300 dark:text-slate-600 hover:text-primary dark:hover:text-primary transition-colors">
<span class="material-symbols-outlined">chevron_right</span>
</button>
</div>
</div>
<!-- List Item 4 -->
<div class="group relative bg-white dark:bg-[#1a2c36] rounded-xl p-4 shadow-sm border border-slate-100 dark:border-slate-800 active:scale-[0.99] transition-transform duration-100">
<div class="flex items-start justify-between gap-4">
<div class="flex items-start gap-3 flex-1">
<div class="h-10 w-10 rounded-lg bg-emerald-50 dark:bg-emerald-900/20 flex items-center justify-center shrink-0 text-emerald-600 dark:text-emerald-400">
<span class="material-symbols-outlined">dns</span>
</div>
<div class="flex flex-col">
<h3 class="font-semibold text-slate-900 dark:text-white text-base leading-snug">analytics-master-01</h3>
<span class="font-mono text-xs text-slate-500 dark:text-slate-400 mt-0.5">10.0.24.128</span>
<div class="flex sm:hidden mt-2 items-center gap-1.5">
<span class="relative flex h-2 w-2">
<span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
<span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
</span>
<span class="text-xs font-medium text-emerald-600 dark:text-emerald-400">Online</span>
</div>
</div>
</div>
<!-- Desktop Status View -->
<div class="hidden sm:flex flex-col items-end gap-1">
<span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300">
<span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                       Online
                   </span>
</div>
<button class="text-slate-300 dark:text-slate-600 hover:text-primary dark:hover:text-primary transition-colors">
<span class="material-symbols-outlined">chevron_right</span>
</button>
</div>
</div>
</main>
<!-- Bottom Action Bar (Fixed) -->
<div class="fixed bottom-0 left-0 right-0 bg-white/80 dark:bg-[#101c22]/80 backdrop-blur-md border-t border-slate-200 dark:border-slate-800 pb-safe-area z-30">
<div class="flex gap-4 p-4 max-w-2xl mx-auto">
<button class="flex-1 h-12 rounded-xl border border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300 font-semibold text-sm hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors flex items-center justify-center gap-2">
<span class="material-symbols-outlined text-[20px]">code</span>
                View Source
            </button>
<button class="flex-1 h-12 rounded-xl bg-primary text-white font-semibold text-sm shadow-lg shadow-primary/30 hover:bg-sky-500 active:bg-sky-600 transition-all transform active:scale-[0.98] flex items-center justify-center gap-2">
<span class="material-symbols-outlined text-[20px]">edit</span>
                Edit Note
            </button>
</div>
<!-- Safe area spacer for notched phones -->
<div class="h-6 w-full"></div>
</div>
</body></html>

<!-- Note View: Card Layout -->
<!DOCTYPE html>

<html class="light" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Note View: Card Layout</title>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#0da2e7",
                        "background-light": "#f5f7f8",
                        "background-dark": "#101c22",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: { "DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "full": "9999px" },
                },
            },
        }
    </script>
<style>
        /* Custom scrollbar hiding for clean mobile look */
        .no-scrollbar::-webkit-scrollbar {
            display: none;
        }
        .no-scrollbar {
            -ms-overflow-style: none;
            scrollbar-width: none;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark font-display text-[#111618] dark:text-white min-h-screen flex flex-col overflow-hidden">
<!-- Top Navigation Bar -->
<header class="flex items-center justify-between px-4 py-3 bg-white dark:bg-[#1A2630] border-b border-gray-100 dark:border-gray-800 sticky top-0 z-10">
<button class="flex items-center justify-center p-2 -ml-2 text-primary hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors">
<span class="material-symbols-outlined text-[24px]">arrow_back_ios_new</span>
</button>
<span class="text-sm font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">Personal</span>
<button class="flex items-center justify-center p-2 -mr-2 text-[#111618] dark:text-white hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors">
<span class="material-symbols-outlined text-[24px]">more_horiz</span>
</button>
</header>
<!-- Main Content Area -->
<main class="flex-1 overflow-y-auto no-scrollbar pb-24 px-4 pt-6">
<!-- Page Header -->
<div class="mb-6">
<h1 class="text-3xl font-bold tracking-tight text-[#111618] dark:text-white mb-2">Gmail Accounts</h1>
<p class="text-gray-500 dark:text-gray-400 text-sm">Last edited 2 hours ago</p>
</div>
<!-- Cards Grid -->
<div class="grid grid-cols-2 gap-4">
<!-- Card 1: Google -->
<div class="bg-white dark:bg-[#1A2630] rounded-lg p-4 shadow-sm border border-gray-100 dark:border-gray-800 flex flex-col justify-between h-full group active:scale-[0.98] transition-transform duration-200">
<div class="flex items-start justify-between mb-3">
<div class="w-10 h-10 rounded-full bg-red-100 dark:bg-red-900/30 flex items-center justify-center text-red-600 dark:text-red-400">
<span class="material-symbols-outlined text-[24px]">mail</span>
</div>
</div>
<div class="mb-4">
<h3 class="font-bold text-lg mb-1 truncate">Google</h3>
<p class="text-xs text-gray-500 dark:text-gray-400 uppercase font-medium tracking-wider mb-1">Username</p>
<p class="text-sm font-medium truncate text-gray-900 dark:text-gray-200">dad@gmail.com</p>
</div>
<button class="w-full mt-auto flex items-center justify-center gap-2 bg-primary/10 hover:bg-primary/20 dark:bg-primary/20 dark:hover:bg-primary/30 text-primary h-9 rounded text-xs font-bold transition-colors">
<span class="material-symbols-outlined text-[16px]">content_copy</span>
<span>Copy</span>
</button>
</div>
<!-- Card 2: Netflix -->
<div class="bg-white dark:bg-[#1A2630] rounded-lg p-4 shadow-sm border border-gray-100 dark:border-gray-800 flex flex-col justify-between h-full group active:scale-[0.98] transition-transform duration-200">
<div class="flex items-start justify-between mb-3">
<div class="w-10 h-10 rounded-full bg-red-100 dark:bg-red-900/30 flex items-center justify-center text-red-600 dark:text-red-400">
<span class="material-symbols-outlined text-[24px]">movie</span>
</div>
</div>
<div class="mb-4">
<h3 class="font-bold text-lg mb-1 truncate">Netflix</h3>
<p class="text-xs text-gray-500 dark:text-gray-400 uppercase font-medium tracking-wider mb-1">Username</p>
<p class="text-sm font-medium truncate text-gray-900 dark:text-gray-200">family_watch</p>
</div>
<button class="w-full mt-auto flex items-center justify-center gap-2 bg-primary/10 hover:bg-primary/20 dark:bg-primary/20 dark:hover:bg-primary/30 text-primary h-9 rounded text-xs font-bold transition-colors">
<span class="material-symbols-outlined text-[16px]">content_copy</span>
<span>Copy</span>
</button>
</div>
<!-- Card 3: Spotify -->
<div class="bg-white dark:bg-[#1A2630] rounded-lg p-4 shadow-sm border border-gray-100 dark:border-gray-800 flex flex-col justify-between h-full group active:scale-[0.98] transition-transform duration-200">
<div class="flex items-start justify-between mb-3">
<div class="w-10 h-10 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center text-green-600 dark:text-green-400">
<span class="material-symbols-outlined text-[24px]">music_note</span>
</div>
</div>
<div class="mb-4">
<h3 class="font-bold text-lg mb-1 truncate">Spotify</h3>
<p class="text-xs text-gray-500 dark:text-gray-400 uppercase font-medium tracking-wider mb-1">Username</p>
<p class="text-sm font-medium truncate text-gray-900 dark:text-gray-200">music_lover</p>
</div>
<button class="w-full mt-auto flex items-center justify-center gap-2 bg-primary/10 hover:bg-primary/20 dark:bg-primary/20 dark:hover:bg-primary/30 text-primary h-9 rounded text-xs font-bold transition-colors">
<span class="material-symbols-outlined text-[16px]">content_copy</span>
<span>Copy</span>
</button>
</div>
<!-- Card 4: Amazon -->
<div class="bg-white dark:bg-[#1A2630] rounded-lg p-4 shadow-sm border border-gray-100 dark:border-gray-800 flex flex-col justify-between h-full group active:scale-[0.98] transition-transform duration-200">
<div class="flex items-start justify-between mb-3">
<div class="w-10 h-10 rounded-full bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center text-orange-600 dark:text-orange-400">
<span class="material-symbols-outlined text-[24px]">shopping_cart</span>
</div>
</div>
<div class="mb-4">
<h3 class="font-bold text-lg mb-1 truncate">Amazon</h3>
<p class="text-xs text-gray-500 dark:text-gray-400 uppercase font-medium tracking-wider mb-1">Username</p>
<p class="text-sm font-medium truncate text-gray-900 dark:text-gray-200">prime_user</p>
</div>
<button class="w-full mt-auto flex items-center justify-center gap-2 bg-primary/10 hover:bg-primary/20 dark:bg-primary/20 dark:hover:bg-primary/30 text-primary h-9 rounded text-xs font-bold transition-colors">
<span class="material-symbols-outlined text-[16px]">content_copy</span>
<span>Copy</span>
</button>
</div>
<!-- Card 5: GitHub -->
<div class="bg-white dark:bg-[#1A2630] rounded-lg p-4 shadow-sm border border-gray-100 dark:border-gray-800 flex flex-col justify-between h-full group active:scale-[0.98] transition-transform duration-200">
<div class="flex items-start justify-between mb-3">
<div class="w-10 h-10 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center text-gray-600 dark:text-gray-300">
<span class="material-symbols-outlined text-[24px]">code</span>
</div>
</div>
<div class="mb-4">
<h3 class="font-bold text-lg mb-1 truncate">GitHub</h3>
<p class="text-xs text-gray-500 dark:text-gray-400 uppercase font-medium tracking-wider mb-1">Username</p>
<p class="text-sm font-medium truncate text-gray-900 dark:text-gray-200">dev_master</p>
</div>
<button class="w-full mt-auto flex items-center justify-center gap-2 bg-primary/10 hover:bg-primary/20 dark:bg-primary/20 dark:hover:bg-primary/30 text-primary h-9 rounded text-xs font-bold transition-colors">
<span class="material-symbols-outlined text-[16px]">content_copy</span>
<span>Copy</span>
</button>
</div>
<!-- Add New Placeholder -->
<div class="bg-transparent rounded-lg p-4 border-2 border-dashed border-gray-300 dark:border-gray-700 flex flex-col items-center justify-center h-full min-h-[160px] group cursor-pointer hover:border-primary transition-colors">
<div class="w-10 h-10 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center text-gray-400 group-hover:text-primary transition-colors mb-2">
<span class="material-symbols-outlined text-[24px]">add</span>
</div>
<span class="text-sm font-bold text-gray-400 group-hover:text-primary transition-colors">Add Account</span>
</div>
</div>
</main>
<!-- Persistent Bottom Action Bar -->
<div class="fixed bottom-0 left-0 w-full bg-white dark:bg-[#1A2630] border-t border-gray-200 dark:border-gray-800 p-4 pb-6 flex gap-3 z-20 shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)]">
<button class="flex-1 h-12 flex items-center justify-center gap-2 rounded-lg border border-gray-300 dark:border-gray-600 text-[#111618] dark:text-white font-bold text-sm hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
<span class="material-symbols-outlined text-[20px]">code</span>
            View Source
        </button>
<button class="flex-1 h-12 flex items-center justify-center gap-2 rounded-lg bg-primary text-white font-bold text-sm shadow-md hover:bg-primary/90 transition-colors">
<span class="material-symbols-outlined text-[20px]">edit</span>
            Edit Note
        </button>
</div>
</body></html>

<!-- Note View: Table Layout -->
<!DOCTYPE html>
<html class="" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Server Inventory - Note View</title>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com" rel="preconnect"/>
<link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#0da2e7",
                        "background-light": "#f5f7f8",
                        "background-dark": "#101c22",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: {"DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "full": "9999px"},
                },
            },
        }
    </script>
<style>.no-scrollbar::-webkit-scrollbar {
            display: none;
        }.no-scrollbar {
            -ms-overflow-style: none;scrollbar-width: none;}.glass-panel {
            background: rgba(16, 28, 34, 0.85);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
        }
    </style>
<style>
        body {
            min-height: max(884px, 100dvh);
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark text-slate-900 dark:text-white font-display antialiased overflow-hidden h-screen flex flex-col">
<header class="shrink-0 pt-12 pb-4 px-4 flex flex-col gap-4 bg-background-light dark:bg-background-dark z-20">
<div class="flex items-center justify-between">
<button class="size-10 flex items-center justify-center rounded-full active:bg-slate-200 dark:active:bg-slate-800 transition-colors text-slate-500 dark:text-slate-400">
<span class="material-symbols-outlined text-2xl">arrow_back_ios_new</span>
</button>
<div class="flex items-center gap-2">
<button class="size-10 flex items-center justify-center rounded-full active:bg-slate-200 dark:active:bg-slate-800 transition-colors text-slate-500 dark:text-slate-400">
<span class="material-symbols-outlined text-2xl">search</span>
</button>
<button class="size-10 flex items-center justify-center rounded-full active:bg-slate-200 dark:active:bg-slate-800 transition-colors text-slate-500 dark:text-slate-400">
<span class="material-symbols-outlined text-2xl">more_horiz</span>
</button>
</div>
</div>
<div class="px-2">
<div class="flex items-center gap-2 text-primary mb-1">
<span class="material-symbols-outlined text-[18px]">folder</span>
<span class="text-sm font-semibold tracking-wide">Infrastructure</span>
</div>
<h1 class="text-3xl font-bold tracking-tight text-slate-900 dark:text-white">Server Inventory</h1>
</div>
</header>
<main class="flex-1 flex flex-col overflow-hidden relative">
<div class="shrink-0 px-4 py-3 bg-slate-100 dark:bg-[#152229] border-b border-slate-200 dark:border-slate-800 grid grid-cols-12 gap-4 text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
<div class="col-span-4 flex items-center">Hostname</div>
<div class="col-span-4 flex items-center">IP Address</div>
<div class="col-span-4 flex items-center justify-end text-right">Last Updated</div>
</div>
<div class="flex-1 overflow-y-auto no-scrollbar pb-32">
<div class="group relative px-4 py-4 grid grid-cols-12 gap-4 border-b border-slate-200 dark:border-slate-800/60 hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors cursor-pointer">
<div class="col-span-4 flex flex-col justify-center">
<span class="text-sm font-semibold text-primary">web-01</span>
<span class="text-[10px] text-slate-400 mt-0.5 sm:hidden">Ubuntu 22.04</span>
</div>
<div class="col-span-4 flex items-center">
<span class="text-sm font-mono text-slate-700 dark:text-slate-300">192.168.1.10</span>
</div>
<div class="col-span-4 flex flex-col items-end justify-center">
<span class="text-sm font-medium text-slate-900 dark:text-white">Oct 27, 2023</span>
<span class="text-[10px] text-slate-500 dark:text-slate-500 font-medium">12 Rab. II</span>
</div>
<div class="absolute right-2 top-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 transition-opacity">
<span class="material-symbols-outlined text-slate-500 text-lg">chevron_right</span>
</div>
</div>
<div class="group relative px-4 py-4 grid grid-cols-12 gap-4 border-b border-slate-200 dark:border-slate-800/60 hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors cursor-pointer">
<div class="col-span-4 flex flex-col justify-center">
<span class="text-sm font-semibold text-primary">db-main-primary</span>
<span class="text-[10px] text-slate-400 mt-0.5 sm:hidden">PostgreSQL 15</span>
</div>
<div class="col-span-4 flex items-center">
<span class="text-sm font-mono text-slate-700 dark:text-slate-300">10.0.0.5</span>
</div>
<div class="col-span-4 flex flex-col items-end justify-center">
<span class="text-sm font-medium text-slate-900 dark:text-white">Oct 26, 2023</span>
<span class="text-[10px] text-slate-500 dark:text-slate-500 font-medium">11 Rab. II</span>
</div>
</div>
<div class="group relative px-4 py-4 grid grid-cols-12 gap-4 border-b border-slate-200 dark:border-slate-800/60 hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors cursor-pointer">
<div class="col-span-4 flex flex-col justify-center">
<span class="text-sm font-semibold text-primary">cache-cluster-02</span>
<span class="text-[10px] text-slate-400 mt-0.5 sm:hidden">Redis 7</span>
</div>
<div class="col-span-4 flex items-center">
<span class="text-sm font-mono text-slate-700 dark:text-slate-300">192.168.1.12</span>
</div>
<div class="col-span-4 flex flex-col items-end justify-center">
<span class="text-sm font-medium text-slate-900 dark:text-white">Oct 25, 2023</span>
<span class="text-[10px] text-slate-500 dark:text-slate-500 font-medium">10 Rab. II</span>
</div>
</div>
<div class="group relative px-4 py-4 grid grid-cols-12 gap-4 border-b border-slate-200 dark:border-slate-800/60 hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors cursor-pointer">
<div class="col-span-4 flex flex-col justify-center">
<span class="text-sm font-semibold text-primary">lb-nginx-01</span>
</div>
<div class="col-span-4 flex items-center">
<span class="text-sm font-mono text-slate-700 dark:text-slate-300">192.168.1.1</span>
</div>
<div class="col-span-4 flex flex-col items-end justify-center">
<span class="text-sm font-medium text-slate-900 dark:text-white">Oct 24, 2023</span>
<span class="text-[10px] text-slate-500 dark:text-slate-500 font-medium">09 Rab. II</span>
</div>
</div>
<div class="group relative px-4 py-4 grid grid-cols-12 gap-4 border-b border-slate-200 dark:border-slate-800/60 hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors cursor-pointer">
<div class="col-span-4 flex flex-col justify-center">
<span class="text-sm font-semibold text-primary">worker-queue-a</span>
</div>
<div class="col-span-4 flex items-center">
<span class="text-sm font-mono text-slate-700 dark:text-slate-300">10.0.2.15</span>
</div>
<div class="col-span-4 flex flex-col items-end justify-center">
<span class="text-sm font-medium text-slate-900 dark:text-white">Oct 23, 2023</span>
<span class="text-[10px] text-slate-500 dark:text-slate-500 font-medium">08 Rab. II</span>
</div>
</div>
<div class="group relative px-4 py-4 grid grid-cols-12 gap-4 border-b border-slate-200 dark:border-slate-800/60 hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors cursor-pointer">
<div class="col-span-4 flex flex-col justify-center">
<span class="text-sm font-semibold text-primary">worker-queue-b</span>
</div>
<div class="col-span-4 flex items-center">
<span class="text-sm font-mono text-slate-700 dark:text-slate-300">10.0.2.16</span>
</div>
<div class="col-span-4 flex flex-col items-end justify-center">
<span class="text-sm font-medium text-slate-900 dark:text-white">Oct 23, 2023</span>
<span class="text-[10px] text-slate-500 dark:text-slate-500 font-medium">08 Rab. II</span>
</div>
</div>
<div class="group relative px-4 py-4 grid grid-cols-12 gap-4 border-b border-slate-200 dark:border-slate-800/60 hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors cursor-pointer">
<div class="col-span-4 flex flex-col justify-center">
<span class="text-sm font-semibold text-primary">backup-cold-01</span>
</div>
<div class="col-span-4 flex items-center">
<span class="text-sm font-mono text-slate-700 dark:text-slate-300">192.168.9.50</span>
</div>
<div class="col-span-4 flex flex-col items-end justify-center">
<span class="text-sm font-medium text-slate-900 dark:text-white">Oct 20, 2023</span>
<span class="text-[10px] text-slate-500 dark:text-slate-500 font-medium">05 Rab. II</span>
</div>
</div>
<div class="p-8 text-center opacity-40">
<p class="text-xs text-slate-500">End of records</p>
</div>
</div>
</main>
<div class="fixed bottom-0 left-0 right-0 p-4 z-30">
<div class="glass-panel w-full rounded-2xl shadow-xl shadow-black/40 border border-white/10 p-3 flex gap-3 items-center">
<button class="flex-1 h-12 rounded-xl bg-primary hover:bg-primary/90 active:scale-[0.98] transition-all flex items-center justify-center gap-2 group shadow-lg shadow-primary/20">
<span class="material-symbols-outlined text-white text-[20px]">edit_note</span>
<span class="text-white font-semibold text-sm">Edit Record</span>
</button>
<button class="flex-1 h-12 rounded-xl bg-slate-700/50 hover:bg-slate-700/70 active:scale-[0.98] transition-all flex items-center justify-center gap-2 group border border-white/5">
<span class="material-symbols-outlined text-primary text-[20px] group-hover:text-white transition-colors">code</span>
<span class="text-slate-200 font-medium text-sm group-hover:text-white transition-colors">View Markdown</span>
</button>
</div>
</div>

</body></html>

<!-- Note View: Grid Layout -->
<!DOCTYPE html>
<html class="" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Subscription Log - Note View</title>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#0da2e7",
                        "background-light": "#f5f7f8",
                        "background-dark": "#101c22",
                        "surface-dark": "#1a262d",
                        "surface-light": "#ffffff",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: {"DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "full": "9999px"},
                },
            },
        }
    </script>
<style>.no-scrollbar::-webkit-scrollbar {
            display: none;
        }
        .no-scrollbar {
            -ms-overflow-style: none;
            scrollbar-width: none;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark text-slate-900 dark:text-white font-display antialiased flex flex-col h-screen overflow-hidden selection:bg-primary/30">
<header class="flex-none bg-background-light dark:bg-background-dark z-20 pt-2 pb-2 px-4 border-b border-slate-200 dark:border-slate-800">
<div class="flex items-center justify-between mb-4">
<button class="flex items-center justify-center w-10 h-10 -ml-2 rounded-full hover:bg-slate-200 dark:hover:bg-slate-800 transition-colors text-slate-600 dark:text-slate-300">
<span class="material-symbols-outlined text-2xl">arrow_back_ios_new</span>
</button>
<div class="flex gap-1">
<button class="flex items-center justify-center w-10 h-10 rounded-full hover:bg-slate-200 dark:hover:bg-slate-800 transition-colors text-slate-600 dark:text-slate-300">
<span class="material-symbols-outlined text-2xl">search</span>
</button>
<button class="flex items-center justify-center w-10 h-10 rounded-full hover:bg-slate-200 dark:hover:bg-slate-800 transition-colors text-slate-600 dark:text-slate-300">
<span class="material-symbols-outlined text-2xl">more_horiz</span>
</button>
</div>
</div>
<div class="flex flex-col gap-1">
<div class="flex items-center gap-2 text-sm text-primary font-medium">
<span class="material-symbols-outlined text-base">folder_open</span>
<span>Personal</span>
</div>
<h1 class="text-3xl font-bold tracking-tight text-slate-900 dark:text-white">Subscription Log</h1>
<div class="flex items-center gap-2 mt-2">
<span class="bg-primary/10 text-primary text-xs px-2 py-1 rounded-full font-medium">Grid View</span>
<span class="text-slate-500 dark:text-slate-400 text-xs">Updated 2h ago</span>
</div>
</div>
</header>
<main class="flex-1 overflow-y-auto p-4 no-scrollbar relative">
<div class="grid grid-cols-1 @xl:grid-cols-2 gap-4 pb-24">
<div class="group relative bg-surface-light dark:bg-surface-dark rounded-xl p-5 shadow-sm border border-slate-200 dark:border-slate-800 hover:border-primary/50 transition-all cursor-pointer">
<div class="flex justify-between items-start mb-3">
<div class="w-12 h-12 rounded-lg bg-black flex items-center justify-center overflow-hidden shrink-0">
<img alt="Netflix Logo" class="w-full h-full object-contain" data-alt="Netflix logo icon" src="https://lh3.googleusercontent.com/aida-public/AB6AXuCqFF1xwC1kmUtlNOVdeqmdAC7d_7zHeTg6say6OpX320eR-l8clz1lQ8mIeSAMjpJHt50Fb3AjaCjyKVOflz7VZgZFoOxKZetwSqb5JFT4Or8n-Ot8CBVf6SBavPaHinlWJW86zXZPQ2tlYH3ltWH_8ZWo4H7_QR_aTbRnGYND_eTpRQu1ViYP1SvIRTZ67q98OIEe9zYJVNUBPBT1qK9Yu_Qh9C2byQHOT63KBro6PPcaz3O4W6lOYZJGI42qSQseQBCF6TcrB64"/>
</div>
<button class="text-slate-400 hover:text-primary transition-colors p-1">
<span class="material-symbols-outlined text-[20px]">open_in_new</span>
</button>
</div>
<h3 class="text-lg font-bold text-slate-900 dark:text-white mb-1">Netflix</h3>
<div class="space-y-2 mt-3">
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Cost</span>
<span class="font-semibold text-slate-700 dark:text-slate-200">$15.99/mo</span>
</div>
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Renewal</span>
<span class="font-medium text-slate-700 dark:text-slate-200">12th of month</span>
</div>
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Type</span>
<span class="bg-red-500/10 text-red-500 px-2 py-0.5 rounded text-xs font-medium">Streaming</span>
</div>
</div>
</div>
<div class="group relative bg-surface-light dark:bg-surface-dark rounded-xl p-5 shadow-sm border border-slate-200 dark:border-slate-800 hover:border-primary/50 transition-all cursor-pointer">
<div class="flex justify-between items-start mb-3">
<div class="w-12 h-12 rounded-lg bg-[#1DB954] flex items-center justify-center overflow-hidden shrink-0 p-2">
<img alt="Spotify Logo" class="w-full h-full object-contain brightness-0 invert" data-alt="Spotify logo icon white" src="https://lh3.googleusercontent.com/aida-public/AB6AXuA_KKYfpttldPF0-aGY_gu8u50iPcuKP_iNlPElKwEbUeur_JZ8sAVyRX_1q2xV9LcfXkGjdHlRZe5cuSYpv68CTFHtpKkLmqG8KwMDrrqVOwGQmAEjFAoEIHQiuw7dZaoiS2eM1EfMrAf3ZY-8oXfK5crAjmbGxFR1_4P_qg3toX6eO5HI3vOnzD7CA4l5CF0XbdS5vPZKv6taHgypoBouNlSnKIiRVCNi9w5wgJeAwNwcH0q0XHdALNGz7YgMRabpdPsn4qJxZuo"/>
</div>
<button class="text-slate-400 hover:text-primary transition-colors p-1">
<span class="material-symbols-outlined text-[20px]">open_in_new</span>
</button>
</div>
<h3 class="text-lg font-bold text-slate-900 dark:text-white mb-1">Spotify</h3>
<div class="space-y-2 mt-3">
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Cost</span>
<span class="font-semibold text-slate-700 dark:text-slate-200">$9.99/mo</span>
</div>
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Renewal</span>
<span class="font-medium text-slate-700 dark:text-slate-200">24th of month</span>
</div>
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Type</span>
<span class="bg-green-500/10 text-green-500 px-2 py-0.5 rounded text-xs font-medium">Music</span>
</div>
</div>
</div>
<div class="group relative bg-surface-light dark:bg-surface-dark rounded-xl p-5 shadow-sm border border-slate-200 dark:border-slate-800 hover:border-primary/50 transition-all cursor-pointer">
<div class="flex justify-between items-start mb-3">
<div class="w-12 h-12 rounded-lg bg-[#FF0000] flex items-center justify-center overflow-hidden shrink-0 p-2">
<span class="font-bold text-white text-xl">Ae</span>
</div>
<button class="text-slate-400 hover:text-primary transition-colors p-1">
<span class="material-symbols-outlined text-[20px]">open_in_new</span>
</button>
</div>
<h3 class="text-lg font-bold text-slate-900 dark:text-white mb-1">Adobe Creative Cloud</h3>
<div class="space-y-2 mt-3">
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Cost</span>
<span class="font-semibold text-slate-700 dark:text-slate-200">$52.99/mo</span>
</div>
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Renewal</span>
<span class="font-medium text-slate-700 dark:text-slate-200">1st of month</span>
</div>
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Type</span>
<span class="bg-indigo-500/10 text-indigo-500 px-2 py-0.5 rounded text-xs font-medium">Software</span>
</div>
</div>
</div>
<div class="group relative bg-surface-light dark:bg-surface-dark rounded-xl p-5 shadow-sm border border-slate-200 dark:border-slate-800 hover:border-primary/50 transition-all cursor-pointer">
<div class="flex justify-between items-start mb-3">
<div class="w-12 h-12 rounded-lg bg-slate-800 flex items-center justify-center overflow-hidden shrink-0 p-2">
<img alt="AWS Logo" class="w-full h-full object-contain brightness-0 invert" data-alt="AWS logo icon white" src="https://lh3.googleusercontent.com/aida-public/AB6AXuDCfb1YV9u_JHWZBT4wbbpwLtkgNFUD9AWv5Vd9YxyLKOtCYeGAhtOdAAFvB0ldgWdkvfoiMl_dBG4VZ_bbPu7wWzpVV-Du66MBfHOUogsSbsyfY85uFPkdk0gLAeQE2qHpfM1K6wImj1G7jke7dAuOZr9K52HMC8a_Zfp7ytFvixFdIUY5AfkOr0lhaiZ694cJ2ITUNs2nFuI7QzeGEbCqVeolRjluVFyidZ4BfLDEwJSBd7LuvDY5rNUXWdholknOlLQQ9nAlTaE"/>
</div>
<button class="text-slate-400 hover:text-primary transition-colors p-1">
<span class="material-symbols-outlined text-[20px]">open_in_new</span>
</button>
</div>
<h3 class="text-lg font-bold text-slate-900 dark:text-white mb-1">AWS</h3>
<div class="space-y-2 mt-3">
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Cost</span>
<span class="font-semibold text-slate-700 dark:text-slate-200">Variable</span>
</div>
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Renewal</span>
<span class="font-medium text-slate-700 dark:text-slate-200">30th of month</span>
</div>
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Type</span>
<span class="bg-orange-500/10 text-orange-500 px-2 py-0.5 rounded text-xs font-medium">Cloud</span>
</div>
</div>
</div>
<div class="group relative bg-surface-light dark:bg-surface-dark rounded-xl p-5 shadow-sm border border-slate-200 dark:border-slate-800 hover:border-primary/50 transition-all cursor-pointer">
<div class="flex justify-between items-start mb-3">
<div class="w-12 h-12 rounded-lg bg-black flex items-center justify-center overflow-hidden shrink-0 p-2">
<img alt="Github Logo" class="w-full h-full object-contain invert" data-alt="Github logo icon white" src="https://lh3.googleusercontent.com/aida-public/AB6AXuCX_rvKNoM9M_VJ6sc4e54x3MJQmvjVWltAjIANAwMZbddgMcy9u3BwNqBGix3y2DlOL2uXjFTId45GdU-gEeuY4YuOy4Ijjk015kTZYJUwAKucz6LaK6x7923lxHOawqMgDA7X5u_9Lq3rXQ1D49s_lNMf-KXGT-LX-NzIH0yE4AuCqsl-OilBk2Gh1npzCG0E71i2Dt9jqfCttaz7SU9CnoysinqmIWDBtUMGEEeY42aOBkX3FjywhnFCZ9ZkRgx8biDuDB13Vu8"/>
</div>
<button class="text-slate-400 hover:text-primary transition-colors p-1">
<span class="material-symbols-outlined text-[20px]">open_in_new</span>
</button>
</div>
<h3 class="text-lg font-bold text-slate-900 dark:text-white mb-1">Github Copilot</h3>
<div class="space-y-2 mt-3">
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Cost</span>
<span class="font-semibold text-slate-700 dark:text-slate-200">$10.00/mo</span>
</div>
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Renewal</span>
<span class="font-medium text-slate-700 dark:text-slate-200">15th of month</span>
</div>
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Type</span>
<span class="bg-blue-500/10 text-blue-500 px-2 py-0.5 rounded text-xs font-medium">Dev Tool</span>
</div>
</div>
</div>
<div class="group relative bg-surface-light dark:bg-surface-dark rounded-xl p-5 shadow-sm border border-slate-200 dark:border-slate-800 hover:border-primary/50 transition-all cursor-pointer">
<div class="flex justify-between items-start mb-3">
<div class="w-12 h-12 rounded-lg bg-[#74aa9c] flex items-center justify-center overflow-hidden shrink-0 p-2">
<span class="material-symbols-outlined text-white text-3xl">smart_toy</span>
</div>
<button class="text-slate-400 hover:text-primary transition-colors p-1">
<span class="material-symbols-outlined text-[20px]">open_in_new</span>
</button>
</div>
<h3 class="text-lg font-bold text-slate-900 dark:text-white mb-1">ChatGPT Plus</h3>
<div class="space-y-2 mt-3">
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Cost</span>
<span class="font-semibold text-slate-700 dark:text-slate-200">$20.00/mo</span>
</div>
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Renewal</span>
<span class="font-medium text-slate-700 dark:text-slate-200">3rd of month</span>
</div>
<div class="flex justify-between items-center text-sm">
<span class="text-slate-500 dark:text-slate-400">Type</span>
<span class="bg-teal-500/10 text-teal-500 px-2 py-0.5 rounded text-xs font-medium">AI</span>
</div>
</div>
</div>
</div>
<div class="fixed bottom-6 left-0 right-0 px-4 z-30 pointer-events-none">
<div class="bg-slate-900/90 dark:bg-white/10 backdrop-blur-md rounded-2xl shadow-xl border border-white/10 mx-auto max-w-sm flex items-center p-1 pointer-events-auto">
<button class="flex-1 flex items-center justify-center gap-2 h-12 rounded-xl text-slate-300 dark:text-slate-300 font-medium hover:bg-white/10 hover:text-white transition-colors">
<span class="material-symbols-outlined text-[20px]">code</span>
            Markdown Source
        </button>
<div class="w-px h-6 bg-white/20 mx-1"></div>
<button class="flex-1 flex items-center justify-center gap-2 h-12 rounded-xl text-primary font-bold hover:bg-white/10 transition-colors">
<span class="material-symbols-outlined text-[20px] filled">edit</span>
            Edit Note
        </button>
</div>
</div>
</main>
</body></html>

<!-- Template Builder -->
<!DOCTYPE html>
<html class="light" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Template Builder</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com" rel="preconnect"/>
<link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<script>
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#0da2e7",
                        "background-light": "#f5f7f8",
                        "background-dark": "#101c22",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: { "DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "full": "9999px" },
                },
            },
        }
    </script>
<style>
        body {
            font-family: 'Inter', sans-serif;
        }.no-scrollbar::-webkit-scrollbar {
            display: none;
        }
        .no-scrollbar {
            -ms-overflow-style: none;
            scrollbar-width: none;
        }
    </style>
<style>
        body {
          min-height: max(884px, 100dvh);
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark text-[#111618] dark:text-white font-display min-h-screen flex flex-col overflow-hidden">
<header class="flex items-center justify-between bg-white dark:bg-[#1a2c36] px-4 py-3 shadow-sm z-20 shrink-0">
<button class="text-[#607d8a] dark:text-gray-400 text-base font-medium leading-normal shrink-0">Cancel</button>
<h2 class="text-[#111618] dark:text-white text-lg font-bold leading-tight tracking-[-0.015em]">Edit Template</h2>
<button class="text-primary text-base font-bold leading-normal shrink-0">Save</button>
</header>
<main class="flex-1 overflow-y-auto overflow-x-hidden p-4 space-y-6 pb-24">
<section class="space-y-3">
<h3 class="text-[#111618] dark:text-white text-sm font-bold uppercase tracking-wide px-1">Template Details</h3>
<div class="bg-white dark:bg-[#1a2c36] rounded-xl shadow-sm border border-gray-100 dark:border-gray-800 p-4 space-y-4">
<div class="space-y-1.5">
<label class="text-[#111618] dark:text-gray-200 text-sm font-medium leading-normal">Template Name</label>
<input class="form-input w-full rounded-lg border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-[#101c22] text-[#111618] dark:text-white focus:border-primary focus:ring-primary h-11 px-3 text-base placeholder:text-gray-400" placeholder="e.g. Weekly Review" type="text" value="Daily Journal"/>
</div>
<div class="space-y-1.5">
<label class="text-[#111618] dark:text-gray-200 text-sm font-medium leading-normal">Template ID</label>
<div class="relative">
<input class="form-input w-full rounded-lg border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-[#101c22] text-gray-600 dark:text-gray-300 focus:border-primary focus:ring-primary h-11 px-3 text-base font-mono text-sm" type="text" value="daily-journal"/>
<span class="material-symbols-outlined absolute right-3 top-3 text-green-500 text-lg">check_circle</span>
</div>
<p class="text-xs text-gray-400 dark:text-gray-500">Unique identifier used for file naming.</p>
</div>
<div class="space-y-1.5 pt-2">
<label class="text-[#111618] dark:text-gray-200 text-sm font-medium leading-normal">Default Layout</label>
<div class="grid grid-cols-4 gap-1 bg-gray-100 dark:bg-[#101c22] p-1 rounded-lg">
<button class="flex flex-col items-center justify-center gap-1 py-2 rounded-md text-xs font-medium text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-200/50 dark:hover:bg-gray-800 transition-colors">
<span class="material-symbols-outlined text-xl">grid_view</span>
                            Grid
                        </button>
<button class="flex flex-col items-center justify-center gap-1 py-2 rounded-md text-xs font-medium text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-200/50 dark:hover:bg-gray-800 transition-colors">
<span class="material-symbols-outlined text-xl">view_list</span>
                            List
                        </button>
<button class="flex flex-col items-center justify-center gap-1 py-2 bg-white dark:bg-[#2c3e4a] shadow-sm rounded-md text-xs font-medium text-primary dark:text-primary">
<span class="material-symbols-outlined text-xl">view_agenda</span>
                            Card
                        </button>
<button class="flex flex-col items-center justify-center gap-1 py-2 rounded-md text-xs font-medium text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-200/50 dark:hover:bg-gray-800 transition-colors">
<span class="material-symbols-outlined text-xl">table_chart</span>
                            Table
                        </button>
</div>
</div>
</div>
</section>
<section class="space-y-3">
<div class="flex items-center justify-between px-1">
<h3 class="text-[#111618] dark:text-white text-sm font-bold uppercase tracking-wide">Fields</h3>
<span class="text-xs font-medium text-gray-400 bg-gray-100 dark:bg-gray-800 px-2 py-0.5 rounded-full">3 Items</span>
</div>
<div class="space-y-3">
<div class="group bg-white dark:bg-[#1a2c36] rounded-xl shadow-sm border border-gray-100 dark:border-gray-800 p-3 flex items-center gap-3 active:scale-[0.99] transition-transform">
<span class="material-symbols-outlined text-gray-400 cursor-grab">drag_indicator</span>
<div class="h-10 w-10 rounded-lg bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center text-primary shrink-0">
<span class="material-symbols-outlined">calendar_today</span>
</div>
<div class="flex-1 min-w-0">
<p class="text-[#111618] dark:text-white font-semibold text-base truncate">Entry Date</p>
<p class="text-xs text-gray-500 dark:text-gray-400 truncate">Date • Required</p>
</div>
<button class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
<span class="material-symbols-outlined">expand_more</span>
</button>
</div>
<div class="bg-white dark:bg-[#1a2c36] rounded-xl shadow-md border-2 border-primary/20 dark:border-primary/20 overflow-hidden relative">
<div class="p-3 bg-primary/5 dark:bg-primary/10 flex items-center gap-3 border-b border-gray-100 dark:border-gray-700">
<span class="material-symbols-outlined text-primary cursor-grab">drag_indicator</span>
<div class="h-10 w-10 rounded-lg bg-primary text-white flex items-center justify-center shrink-0 shadow-sm">
<span class="material-symbols-outlined">mood</span>
</div>
<div class="flex-1 min-w-0">
<p class="text-[#111618] dark:text-white font-bold text-base truncate">Mood Tracker</p>
<p class="text-xs text-primary font-medium truncate">Editing...</p>
</div>
<button class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400">
<span class="material-symbols-outlined">expand_less</span>
</button>
</div>
<div class="p-4 space-y-4">
<div class="grid grid-cols-2 gap-4">
<div class="space-y-1.5">
<label class="text-[#111618] dark:text-gray-200 text-xs font-bold uppercase tracking-wider">Label</label>
<input class="form-input w-full rounded-lg border-gray-200 dark:border-gray-700 bg-white dark:bg-[#101c22] text-[#111618] dark:text-white focus:border-primary focus:ring-primary h-10 px-3 text-sm" type="text" value="Mood"/>
</div>
<div class="space-y-1.5">
<label class="text-[#111618] dark:text-gray-200 text-xs font-bold uppercase tracking-wider">Type</label>
<div class="relative">
<select class="form-select w-full rounded-lg border-gray-200 dark:border-gray-700 bg-white dark:bg-[#101c22] text-[#111618] dark:text-white focus:border-primary focus:ring-primary h-10 pl-3 pr-8 text-sm appearance-none">
<option>Text</option>
<option>Number</option>
<option selected="">Single Select</option>
<option>Multi Select</option>
</select>
</div>
</div>
</div>
<div class="space-y-1.5">
<label class="text-[#111618] dark:text-gray-200 text-xs font-bold uppercase tracking-wider">Field ID</label>
<input class="form-input w-full rounded-lg border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-[#101c22] text-gray-600 dark:text-gray-300 focus:border-primary focus:ring-primary h-10 px-3 text-sm font-mono" type="text" value="mood_select"/>
</div>
<div class="space-y-2 pt-2 border-t border-gray-100 dark:border-gray-700">
<div class="flex items-center justify-between">
<label class="text-[#111618] dark:text-gray-200 text-xs font-bold uppercase tracking-wider">Options</label>
<button class="text-xs text-primary font-bold hover:text-primary/80">
                                    + Add Option
                                </button>
</div>
<div class="space-y-2">
<div class="flex items-center gap-2">
<span class="material-symbols-outlined text-gray-300 text-lg cursor-grab">drag_handle</span>
<div class="h-2 w-2 rounded-full bg-green-500"></div>
<input class="flex-1 bg-transparent border-0 border-b border-gray-200 dark:border-gray-700 focus:border-primary focus:ring-0 p-1 text-sm text-gray-800 dark:text-gray-200" type="text" value="Happy"/>
<button class="text-gray-400 hover:text-red-500">
<span class="material-symbols-outlined text-lg">close</span>
</button>
</div>
<div class="flex items-center gap-2">
<span class="material-symbols-outlined text-gray-300 text-lg cursor-grab">drag_handle</span>
<div class="h-2 w-2 rounded-full bg-yellow-500"></div>
<input class="flex-1 bg-transparent border-0 border-b border-gray-200 dark:border-gray-700 focus:border-primary focus:ring-0 p-1 text-sm text-gray-800 dark:text-gray-200" type="text" value="Neutral"/>
<button class="text-gray-400 hover:text-red-500">
<span class="material-symbols-outlined text-lg">close</span>
</button>
</div>
<div class="flex items-center gap-2">
<span class="material-symbols-outlined text-gray-300 text-lg cursor-grab">drag_handle</span>
<div class="h-2 w-2 rounded-full bg-red-500"></div>
<input class="flex-1 bg-transparent border-0 border-b border-gray-200 dark:border-gray-700 focus:border-primary focus:ring-0 p-1 text-sm text-gray-800 dark:text-gray-200" type="text" value="Sad"/>
<button class="text-gray-400 hover:text-red-500">
<span class="material-symbols-outlined text-lg">close</span>
</button>
</div>
</div>
</div>
<div class="pt-2 flex justify-end gap-3">
<button class="text-red-500 text-sm font-medium hover:text-red-600 flex items-center gap-1">
<span class="material-symbols-outlined text-base">delete</span> Delete Field
                            </button>
</div>
</div>
</div>
<div class="group bg-white dark:bg-[#1a2c36] rounded-xl shadow-sm border border-gray-100 dark:border-gray-800 p-3 flex items-center gap-3 active:scale-[0.99] transition-transform opacity-70 hover:opacity-100">
<span class="material-symbols-outlined text-gray-400 cursor-grab">drag_indicator</span>
<div class="h-10 w-10 rounded-lg bg-orange-50 dark:bg-orange-900/20 flex items-center justify-center text-orange-500 shrink-0">
<span class="material-symbols-outlined">title</span>
</div>
<div class="flex-1 min-w-0">
<p class="text-[#111618] dark:text-white font-semibold text-base truncate">Daily Title</p>
<p class="text-xs text-gray-500 dark:text-gray-400 truncate">Text • Optional</p>
</div>
<button class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
<span class="material-symbols-outlined">expand_more</span>
</button>
</div>
</div>
<div class="pt-4 space-y-4">
<button class="w-full py-3 rounded-xl border-2 border-dashed border-gray-300 dark:border-gray-600 text-gray-500 dark:text-gray-400 font-semibold flex items-center justify-center gap-2 hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
<span class="material-symbols-outlined">add_circle</span>
                    Add Field
                </button>
<button class="w-full bg-primary hover:bg-primary/90 text-white rounded-xl py-3.5 font-bold shadow-lg shadow-primary/30 flex items-center justify-center gap-2 text-base transition-all active:scale-[0.98]">
<span class="material-symbols-outlined">visibility</span>
                    Preview Template
                </button>
</div>
</section>
</main>
</body></html>