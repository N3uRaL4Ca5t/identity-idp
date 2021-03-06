import React, { createRef } from 'react';
import sinon from 'sinon';
import userEvent from '@testing-library/user-event';
import { fireEvent } from '@testing-library/react';
import { expect } from 'chai';
import FileInput, {
  getAcceptPattern,
  isImage,
  isValidForAccepts,
} from '@18f/identity-document-capture/components/file-input';
import DeviceContext from '@18f/identity-document-capture/context/device';
import render from '../../../support/render';

describe('document-capture/components/file-input', () => {
  describe('getAcceptPattern', () => {
    it('returns a pattern for audio matching', () => {
      const accept = 'audio/*';
      const pattern = getAcceptPattern(accept);

      expect(pattern.test('audio/mp3')).to.be.true();
      expect(pattern.test('xaudio/mp3')).to.be.false();
      expect(pattern.test('video/mp4')).to.be.false();
      expect(pattern.test('image/jpg')).to.be.false();
    });

    it('returns a pattern for video matching', () => {
      const accept = 'video/*';
      const pattern = getAcceptPattern(accept);

      expect(pattern.test('video/mp4')).to.be.true();
      expect(pattern.test('xvideo/mp4')).to.be.false();
      expect(pattern.test('audio/mp3')).to.be.false();
      expect(pattern.test('image/jpg')).to.be.false();
    });

    it('returns a pattern for image matching', () => {
      const accept = 'image/*';
      const pattern = getAcceptPattern(accept);

      expect(pattern.test('image/jpg')).to.be.true();
      expect(pattern.test('ximage/jpg')).to.be.false();
      expect(pattern.test('audio/mp3')).to.be.false();
      expect(pattern.test('video/mp4')).to.be.false();
    });

    it('returns a pattern for mime type matching', () => {
      const accept = 'image/jpg';
      const pattern = getAcceptPattern(accept);

      expect(pattern.test('image/jpg')).to.be.true();
      expect(pattern.test('ximage/jpg')).to.be.false();
      expect(pattern.test('audio/mp3')).to.be.false();
      expect(pattern.test('video/mp4')).to.be.false();
    });

    it('returns undefined for unknown accept', () => {
      const accept = 'jpg';
      const pattern = getAcceptPattern(accept);

      expect(pattern).to.be.undefined();
    });

    it('returns undefined for file extension matching', () => {
      const accept = '.jpg';
      const pattern = getAcceptPattern(accept);

      expect(pattern).to.be.undefined();
    });
  });

  describe('isImage', () => {
    it('returns false if given file is not an image', () => {
      expect(isImage(new window.File([], 'demo.txt', { type: 'text/plain' }))).to.be.false();
    });

    it('returns true if given file is an image', () => {
      expect(isImage(new window.File([], 'demo.png', { type: 'image/png' }))).to.be.true();
    });
  });

  describe('isValidForAccepts', () => {
    it('returns false if invalid', () => {
      const url = 'text/plain';
      const accept = ['image/*'];

      expect(isValidForAccepts(url, accept)).to.be.false();
    });

    it('returns true if valid', () => {
      const url = 'image/gif';
      const accept = ['image/*'];

      expect(isValidForAccepts(url, accept)).to.be.true();
    });

    it('returns true if accept is nullish', () => {
      const url = 'image/gif';
      const accept = null;

      expect(isValidForAccepts(url, accept)).to.be.true();
    });
  });

  it('renders file input with label', () => {
    const { getByLabelText } = render(<FileInput label="File" />);

    const input = getByLabelText('File');

    expect(input.nodeName).to.equal('INPUT');
    expect(input.type).to.equal('file');
  });

  it('renders decorative banner text', () => {
    const { getByText } = render(
      <FileInput label="File" bannerText="File Goes Here" className="my-custom-class" />,
    );

    expect(getByText('File Goes Here', { hidden: true })).to.be.ok();
  });

  it('renders an optional hint', () => {
    const { getByLabelText } = render(<FileInput label="File" hint="Must be small" />);

    const input = getByLabelText('File');
    const hint = document.getElementById(input.getAttribute('aria-describedby')).textContent;

    expect(hint).to.equal('Must be small');
  });

  it('renders a value preview for a file', async () => {
    const { container, findByRole, getByLabelText } = render(
      <FileInput label="File" value={new window.File([], 'demo.png', { type: 'image/png' })} />,
    );

    const preview = await findByRole('img', { hidden: true });
    const input = getByLabelText('File');

    expect(input).to.be.ok();
    expect(preview.getAttribute('src')).to.match(/^data:image\/png;base64,/);
    expect(container.querySelector('.usa-file-input__preview-heading').textContent).to.equal(
      'doc_auth.forms.selected_file: demo.png doc_auth.forms.change_file',
    );
  });

  it('does not render preview if value is not image', () => {
    const { container } = render(
      <FileInput label="File" value={new window.File([], 'demo.txt', { type: 'text/plain' })} />,
    );

    expect(container.querySelector('.usa-file-input__preview')).to.not.be.ok();
  });

  it('limits to accepted file mime types', () => {
    const { getByLabelText } = render(
      <FileInput label="File" accept={['image/png', 'image/bmp']} />,
    );

    expect(getByLabelText('File').accept).to.equal('image/png,image/bmp');
  });

  it('calls onChange with next value', () => {
    const file = new window.File([''], 'upload.png', { type: 'image/png' });
    const onChange = sinon.stub();
    const { getByLabelText } = render(<FileInput label="File" onChange={onChange} />);

    const input = getByLabelText('File');
    userEvent.upload(input, file);

    expect(onChange.getCall(0).args[0]).to.equal(file);
  });

  it('allows changing the selected value', () => {
    const file1 = new window.File([''], 'upload1.png', { type: 'image/png' });
    const file2 = new window.File([''], 'upload2.png', { type: 'image/png' });
    const onChange = sinon.stub();
    const { getByLabelText } = render(<FileInput label="File" onChange={onChange} />);

    const input = getByLabelText('File');
    userEvent.upload(input, file1);
    userEvent.upload(input, file2);

    expect(onChange.getCall(0).args[0]).to.equal(file1);
    expect(onChange.getCall(1).args[0]).to.equal(file2);
  });

  it('allows clearing the selected value', () => {
    const file = new window.File([''], 'upload1.png', { type: 'image/png' });
    const onChange = sinon.stub();
    const { getByLabelText } = render(<FileInput label="File" onChange={onChange} />);

    const input = getByLabelText('File');
    userEvent.upload(input, file);
    fireEvent.change(input, { target: { files: [] } });
    expect(onChange.getCall(1).args[0]).to.be.null();
    expect(input.value).to.be.empty();
  });

  it('omits desktop-relevant details in mobile context', async () => {
    const { container, getByText, findByRole, rerender } = render(
      <DeviceContext.Provider value={{ isMobile: true }}>
        <FileInput label="File" />
      </DeviceContext.Provider>,
    );

    expect(getByText('doc_auth.forms.choose_file_html', { hidden: true })).to.be.ok();

    rerender(
      <DeviceContext.Provider value={{ isMobile: true }}>
        <FileInput label="File" bannerText="File goes here" />
      </DeviceContext.Provider>,
    );

    expect(() => getByText('doc_auth.forms.choose_file_html', { hidden: true })).to.throw();
    expect(getByText('File goes here', { hidden: true })).to.be.ok();

    rerender(
      <DeviceContext.Provider value={{ isMobile: true }}>
        <FileInput
          label="File"
          bannerText="File goes here"
          value={new window.File([], 'demo.png', { type: 'image/png' })}
        />
      </DeviceContext.Provider>,
    );

    await findByRole('img', { hidden: true });
    expect(container.querySelector('.usa-file-input__preview-heading')).to.not.be.ok();
  });

  it('adds drag effects', () => {
    const { getByLabelText } = render(<FileInput label="File" />);

    const input = getByLabelText('File');
    const container = input.closest('.usa-file-input');

    fireEvent.dragOver(input);
    expect(container.classList.contains('usa-file-input--drag')).to.be.true();

    fireEvent.dragLeave(input);
    expect(container.classList.contains('usa-file-input--drag')).to.be.false();

    fireEvent.dragOver(input);
    expect(container.classList.contains('usa-file-input--drag')).to.be.true();

    fireEvent.drop(input);
    expect(container.classList.contains('usa-file-input--drag')).to.be.false();
  });

  it('shows an error state', () => {
    const file = new window.File([''], 'upload.png', { type: 'image/png' });
    const onChange = sinon.stub();
    const onError = sinon.stub();
    const { getByLabelText, getByText } = render(
      <FileInput label="File" accept={['text/*']} onChange={onChange} onError={onError} />,
    );

    const input = getByLabelText('File');
    userEvent.upload(input, file);

    expect(getByText('errors.doc_auth.selfie')).to.be.ok();
    expect(onError.getCall(0).args[0]).to.equal('errors.doc_auth.selfie');
  });

  it('shows an error from rendering parent', () => {
    const file = new window.File([''], 'upload.png', { type: 'image/png' });
    const onChange = sinon.stub();
    const onError = sinon.stub();
    const props = { label: 'File', accept: ['text/*'], onChange, onError };
    const { getByLabelText, getByText, rerender } = render(<FileInput {...props} />);

    const input = getByLabelText('File');
    userEvent.upload(input, file);

    expect(getByText('errors.doc_auth.selfie')).to.be.ok();
    expect(onError.getCall(0).args[0]).to.equal('errors.doc_auth.selfie');

    rerender(<FileInput {...props} errorMessage="Oops!" />);

    expect(getByText('Oops!')).to.be.ok();
    expect(() => getByText('errors.doc_auth.selfie')).to.throw();
    expect(onError.callCount).to.equal(1);
  });

  it('forwards ref', () => {
    const ref = createRef();
    render(<FileInput ref={ref} label="File" />);

    expect(ref.current.nodeName).to.equal('INPUT');
  });
});
