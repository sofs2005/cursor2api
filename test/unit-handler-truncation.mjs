import { shouldAutoContinueTruncatedToolResponse } from '../dist/handler.js';

let passed = 0;
let failed = 0;

function test(name, fn) {
    try {
        fn();
        console.log(`  ✅ ${name}`);
        passed++;
    } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        console.error(`  ❌ ${name}`);
        console.error(`      ${message}`);
        failed++;
    }
}

function assertEqual(actual, expected, message) {
    if (actual !== expected) {
        throw new Error(message || `Expected ${expected}, got ${actual}`);
    }
}

console.log('\n📦 handler 截断续写判定\n');

test('短参数工具调用可恢复时不再继续续写', () => {
    const text = [
        '我先读取配置文件。',
        '',
        '```json action',
        '{',
        '  "tool": "Read",',
        '  "parameters": {',
        '    "file_path": "/app/config.yaml"',
        '  }',
    ].join('\n');

    assertEqual(
        shouldAutoContinueTruncatedToolResponse(text, true),
        false,
        'Read 这类短参数工具不应继续续写',
    );
});

test('大参数写入工具仍然继续续写', () => {
    const longContent = 'A'.repeat(4000);
    const text = [
        '```json action',
        '{',
        '  "tool": "Write",',
        '  "parameters": {',
        '    "file_path": "/tmp/large.txt",',
        `    "content": "${longContent}`,
    ].join('\n');

    assertEqual(
        shouldAutoContinueTruncatedToolResponse(text, true),
        true,
        'Write 大内容仍应继续续写以补全参数',
    );
});

test('无工具代码块但文本明显截断时继续续写', () => {
    const text = '```ts\nexport const answer = {';

    assertEqual(
        shouldAutoContinueTruncatedToolResponse(text, true),
        true,
        '未形成可恢复工具调用时应继续续写',
    );
});

console.log(`\n结果: ${passed} 通过 / ${failed} 失败 / ${passed + failed} 总计\n`);

if (failed > 0) process.exit(1);
