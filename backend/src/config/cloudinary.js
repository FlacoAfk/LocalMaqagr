// Local mode: Cloudinary disabled. Storage is local filesystem (see storage.js).
// This stub exists only so that any stray import does not crash the app.

const noop = () => {};
const asyncNoop = async () => {};

const cloudinaryStub = {
  config: noop,
  uploader: {
    upload: asyncNoop,
    upload_stream: asyncNoop,
    destroy: asyncNoop,
  },
  api: {
    delete_resources: asyncNoop,
  },
};

export default cloudinaryStub;
