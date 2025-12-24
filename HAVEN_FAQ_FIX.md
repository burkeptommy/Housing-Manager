# Haven FAQ Styling Fix

## PROBLEM

In the FAQ section on the homepage:
- Question text: Dark (correct)
- Answer text: Light gray (too light, inconsistent)

The answer should be clearly readable and have consistent styling with the question.

---

## FIX

### File: `apps/web/src/app/page.tsx` (FAQ Section)

Find the FAQ accordion/section and update the answer text color:

```tsx
{/* FAQ Section */}
<section id="faq" className="py-16 sm:py-24 bg-white">
  <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
    <h2 className="text-3xl sm:text-4xl font-bold text-center text-warm-900 mb-12">
      Questions? We've Got Answers.
    </h2>
    
    <div className="space-y-4">
      {faqs.map((faq, index) => (
        <div 
          key={index}
          className="bg-white border border-warm-200 rounded-xl overflow-hidden"
        >
          {/* Question - clickable header */}
          <button
            onClick={() => toggleFaq(index)}
            className="w-full flex items-center justify-between px-6 py-4 text-left hover:bg-warm-50 transition-colors"
          >
            <span className="font-semibold text-warm-900">{faq.question}</span>
            <ChevronDown 
              className={`w-5 h-5 text-warm-500 transition-transform ${
                openIndex === index ? 'rotate-180' : ''
              }`} 
            />
          </button>
          
          {/* Answer - expanded content */}
          {openIndex === index && (
            <div className="px-6 pb-4">
              {/* FIX: Change text-warm-500 to text-warm-600 or text-warm-700 */}
              <p className="text-warm-600 leading-relaxed">
                {faq.answer}
              </p>
            </div>
          )}
        </div>
      ))}
    </div>
  </div>
</section>
```

### Color Fix Details

| Element | Before | After |
|---------|--------|-------|
| Question | `text-warm-900` | `text-warm-900` (no change) |
| Answer | `text-warm-400` or `text-warm-500` | `text-warm-600` |

### Alternative: Use warm-700 for even better readability

```tsx
<p className="text-warm-700 leading-relaxed">
  {faq.answer}
</p>
```

---

## SEARCH & REPLACE

Find in `apps/web/src/app/page.tsx`:

```tsx
// Look for FAQ answer styling like:
className="text-warm-400"
// or
className="text-warm-500"
// or  
className="text-gray-500"
// or
className="text-gray-400"
```

Replace with:
```tsx
className="text-warm-600"
```

---

## ADDITIONAL STYLING IMPROVEMENTS

### Better FAQ Card Design

```tsx
{/* Enhanced FAQ item */}
<div className="border border-warm-200 rounded-xl overflow-hidden bg-white shadow-soft">
  {/* Question */}
  <button
    onClick={() => toggleFaq(index)}
    className="w-full flex items-center justify-between px-6 py-5 text-left 
               hover:bg-warm-50 transition-colors group"
  >
    <span className="font-semibold text-warm-900 group-hover:text-haven-700 transition-colors">
      {faq.question}
    </span>
    <div className="flex-shrink-0 ml-4">
      <ChevronDown 
        className={`w-5 h-5 text-warm-400 group-hover:text-haven-600 transition-all ${
          openIndex === index ? 'rotate-180 text-haven-600' : ''
        }`} 
      />
    </div>
  </button>
  
  {/* Answer */}
  {openIndex === index && (
    <div className="px-6 pb-5 pt-0 border-t border-warm-100 bg-warm-50/50">
      <p className="text-warm-700 leading-relaxed pt-4">
        {faq.answer}
      </p>
    </div>
  )}
</div>
```

---

## EXECUTION

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Paste:

```
Fix FAQ answer text color on homepage:

1. In apps/web/src/app/page.tsx, find the FAQ section

2. Find the answer text styling (likely text-warm-400 or text-warm-500 or text-gray-500)

3. Change answer text color to text-warm-600 or text-warm-700 for better readability

4. The question should be text-warm-900 (dark)
   The answer should be text-warm-600 or text-warm-700 (readable, but slightly lighter)

5. Optionally add bg-warm-50/50 to the expanded answer area for subtle distinction

Run pnpm build to verify.
```
