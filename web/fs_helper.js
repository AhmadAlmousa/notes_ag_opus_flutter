// File System Helper for Organote
// Handles File System Access API + OPFS fallback

(function () {
    'use strict';

    const DB_NAME = 'organote_fs';
    const DB_STORE = 'dir_handles';
    const HANDLE_KEY = 'root_dir';

    // ─── Feature Detection ───
    window.organoteFS = {
        // Check if File System Access API (showDirectoryPicker) is supported
        isFileSystemAccessSupported: function () {
            return typeof window.showDirectoryPicker === 'function';
        },

        // Check if OPFS is supported
        isOPFSSupported: function () {
            return navigator.storage && typeof navigator.storage.getDirectory === 'function';
        },

        // Get best available storage type: 'fsa', 'opfs', or 'none'
        getBestStorageType: function () {
            if (this.isFileSystemAccessSupported()) return 'fsa';
            if (this.isOPFSSupported()) return 'opfs';
            return 'none';
        },

        // ─── IndexedDB Helpers (persist directory handle) ───
        _openDB: function () {
            return new Promise((resolve, reject) => {
                const req = indexedDB.open(DB_NAME, 1);
                req.onupgradeneeded = () => req.result.createObjectStore(DB_STORE);
                req.onsuccess = () => resolve(req.result);
                req.onerror = () => reject(req.error);
            });
        },

        _saveHandle: async function (handle) {
            const db = await this._openDB();
            const tx = db.transaction(DB_STORE, 'readwrite');
            tx.objectStore(DB_STORE).put(handle, HANDLE_KEY);
            return new Promise((resolve, reject) => {
                tx.oncomplete = () => resolve();
                tx.onerror = () => reject(tx.error);
            });
        },

        _loadHandle: async function () {
            const db = await this._openDB();
            const tx = db.transaction(DB_STORE, 'readonly');
            const req = tx.objectStore(DB_STORE).get(HANDLE_KEY);
            return new Promise((resolve, reject) => {
                req.onsuccess = () => resolve(req.result || null);
                req.onerror = () => reject(req.error);
            });
        },

        _clearHandle: async function () {
            const db = await this._openDB();
            const tx = db.transaction(DB_STORE, 'readwrite');
            tx.objectStore(DB_STORE).delete(HANDLE_KEY);
            return new Promise((resolve, reject) => {
                tx.oncomplete = () => resolve();
                tx.onerror = () => reject(tx.error);
            });
        },

        // ─── Directory Handle (FSA or OPFS) ───
        _rootHandle: null,
        _storageType: null,

        // Pick a directory using File System Access API
        pickDirectory: async function () {
            if (!this.isFileSystemAccessSupported()) {
                throw new Error('File System Access API not supported');
            }
            const handle = await window.showDirectoryPicker({ mode: 'readwrite' });
            this._rootHandle = handle;
            this._storageType = 'fsa';
            await this._saveHandle(handle);
            return handle.name;
        },

        // Use OPFS as storage
        useOPFS: async function () {
            if (!this.isOPFSSupported()) {
                throw new Error('OPFS not supported');
            }
            this._rootHandle = await navigator.storage.getDirectory();
            this._storageType = 'opfs';
            return 'Origin Private File System';
        },

        // Reconnect to previously saved FSA directory
        reconnect: async function () {
            const handle = await this._loadHandle();
            if (!handle) return null;

            // Verify permission
            const perm = await handle.queryPermission({ mode: 'readwrite' });
            if (perm === 'granted') {
                this._rootHandle = handle;
                this._storageType = 'fsa';
                return handle.name;
            }

            // Try requesting permission
            const reqPerm = await handle.requestPermission({ mode: 'readwrite' });
            if (reqPerm === 'granted') {
                this._rootHandle = handle;
                this._storageType = 'fsa';
                return handle.name;
            }

            return null;
        },

        // Get current storage type  
        getStorageType: function () {
            return this._storageType || 'none';
        },

        // Get current directory name
        getDirectoryName: function () {
            if (!this._rootHandle) return null;
            if (this._storageType === 'opfs') return 'Origin Private File System';
            return this._rootHandle.name;
        },

        // ─── File Operations ───

        // Get or create a subdirectory handle from path parts
        _getDir: async function (pathParts, create) {
            if (!this._rootHandle) throw new Error('No directory selected');
            let dir = this._rootHandle;
            for (const part of pathParts) {
                dir = await dir.getDirectoryHandle(part, { create: create !== false });
            }
            return dir;
        },

        // Write a file at the given path (e.g., "notes/personal/myfile.md")
        writeFile: async function (path, content) {
            const parts = path.split('/');
            const fileName = parts.pop();
            const dir = await this._getDir(parts, true);
            const fileHandle = await dir.getFileHandle(fileName, { create: true });
            const writable = await fileHandle.createWritable();
            await writable.write(content);
            await writable.close();
        },

        // Read a file at the given path
        readFile: async function (path) {
            const parts = path.split('/');
            const fileName = parts.pop();
            const dir = await this._getDir(parts, false);
            const fileHandle = await dir.getFileHandle(fileName);
            const file = await fileHandle.getFile();
            return await file.text();
        },

        // Delete a file at the given path
        deleteFile: async function (path) {
            const parts = path.split('/');
            const fileName = parts.pop();
            const dir = await this._getDir(parts, false);
            await dir.removeEntry(fileName);
        },

        // List all files in a directory recursively
        // Returns array of { path: string, isFile: boolean }
        listFiles: async function (dirPath) {
            const parts = dirPath ? dirPath.split('/').filter(p => p) : [];
            let dir;
            try {
                dir = await this._getDir(parts, false);
            } catch (e) {
                return [];
            }

            const results = [];
            await this._listRecursive(dir, dirPath || '', results);
            return results;
        },

        _listRecursive: async function (dirHandle, prefix, results) {
            for await (const [name, handle] of dirHandle.entries()) {
                const fullPath = prefix ? prefix + '/' + name : name;
                if (handle.kind === 'file') {
                    results.push({ path: fullPath, isFile: true });
                } else {
                    results.push({ path: fullPath, isFile: false });
                    await this._listRecursive(handle, fullPath, results);
                }
            }
        },

        // Check if a file exists
        fileExists: async function (path) {
            try {
                const parts = path.split('/');
                const fileName = parts.pop();
                const dir = await this._getDir(parts, false);
                await dir.getFileHandle(fileName);
                return true;
            } catch (e) {
                return false;
            }
        },

        // Check if directory exists
        directoryExists: async function (path) {
            try {
                const parts = path.split('/').filter(p => p);
                await this._getDir(parts, false);
                return true;
            } catch (e) {
                return false;
            }
        },

        // Get all notes as { "category/filename": content }
        getAllNotes: async function () {
            const notes = {};
            try {
                const dir = await this._getDir(['notes'], false);
                await this._readAllInDir(dir, '', notes);
            } catch (e) {
                // notes dir doesn't exist yet
            }
            return notes;
        },

        // Get all templates as { "templateId": content }
        getAllTemplates: async function () {
            const templates = {};
            const promises = [];
            try {
                const dir = await this._getDir(['templates'], false);
                for await (const [name, handle] of dir.entries()) {
                    if (handle.kind === 'file' && name.endsWith('.md')) {
                        promises.push((async () => {
                            const file = await handle.getFile();
                            const content = await file.text();
                            templates[name.replace('.md', '')] = content;
                        })());
                    }
                }
                await Promise.all(promises);
            } catch (e) {
                // templates dir doesn't exist yet
            }
            return templates;
        },

        _readAllInDir: async function (dirHandle, prefix, results) {
            const promises = [];
            for await (const [name, handle] of dirHandle.entries()) {
                const path = prefix ? prefix + '/' + name : name;
                if (handle.kind === 'file') {
                    promises.push((async () => {
                        const file = await handle.getFile();
                        results[path] = await file.text();
                    })());
                } else {
                    promises.push(this._readAllInDir(handle, path, results));
                }
            }
            await Promise.all(promises);
        },

        // Initialize - ensure notes/ and templates/ directories exist
        initDirectories: async function () {
            if (!this._rootHandle) throw new Error('No directory selected');
            await this._rootHandle.getDirectoryHandle('notes', { create: true });
            await this._rootHandle.getDirectoryHandle('templates', { create: true });
        },

        // Disconnect current storage
        disconnect: async function () {
            this._rootHandle = null;
            this._storageType = null;
            await this._clearHandle();
        }
    };
})();
